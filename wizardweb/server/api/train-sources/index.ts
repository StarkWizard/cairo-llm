import fs from "fs";
import path from "path";
import { parse } from "csv-parse";
import type { CsvSummary, TreeNode } from "~/types/api.types";
import { ROOT_FOLDER_PATH } from "./_utils";
import { simpleGit } from "simple-git";

const getCsvSummary = async (filePath: string): Promise<CsvSummary | undefined> => {
  if (!filePath.endsWith(".csv")) return undefined;

  try {
    const parser = fs.createReadStream(filePath).pipe(parse({ delimiter: "," }));
    let count = -1; // Do not count header
    for await (const record of parser) {
      count++;
    }
    return {
      nbRows: count,
    };
  } catch (error) {
    return {
      error: error as Error,
    };
  }
};

const git = simpleGit();
const getUpdatedAt = async (filePath: string): Promise<string> => {
  const log = await git.log({
    file: filePath,
    maxCount: 1,
  });
  return log.all?.[0]?.date ?? new Date().toISOString();
};

const getFolderStructure = async (folderPath: string): Promise<TreeNode[]> => {
  const stats = fs.statSync(folderPath);

  if (!stats.isDirectory()) {
    const _path = path.resolve(folderPath);
    return [
      {
        label: path.basename(folderPath),
        path: _path,
        type: "file",
        data: await getCsvSummary(_path),
        updatedAt: await getUpdatedAt(_path),
      },
    ];
  }

  const items = fs.readdirSync(folderPath);
  const structure = await Promise.all(
    items.map(async (item) => {
      const itemPath = path.join(folderPath, item);
      const isDirectory = fs.statSync(itemPath).isDirectory();

      if (isDirectory) {
        const children = await getFolderStructure(itemPath);
        return {
          label: item,
          children,
          path: path.resolve(folderPath, item),
          type: "folder",
        };
      } else if (item.endsWith(".csv")) {
        return {
          label: item,
          path: path.resolve(folderPath, item),
          type: "file",
          data: await getCsvSummary(path.resolve(folderPath, item)),
          updatedAt: await getUpdatedAt(path.resolve(folderPath, item)),
        };
      }
    }),
  );

  return structure as TreeNode[];
};

export default defineEventHandler(async (event) => {
  const folderStructure = await getFolderStructure(ROOT_FOLDER_PATH);
  return folderStructure;
});
