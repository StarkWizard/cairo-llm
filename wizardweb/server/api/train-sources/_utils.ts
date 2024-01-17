import fs from "fs";
import path from "path";
import { parse } from "csv-parse";
import type { CsvData, TreeNode } from "~/types/api.types";
export const ROOT_FOLDER_PATH = "../corpus_src/train";

export const getCsvSummary = async (filePath: string): Promise<CsvData | undefined> => {
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

export const getFolderStructure = async (folderPath: string): Promise<TreeNode[]> => {
  const stats = fs.statSync(folderPath);

  if (!stats.isDirectory()) {
    return [
      {
        label: path.basename(folderPath),
        path: path.resolve(folderPath),
        type: "file",
        data: await getCsvSummary(path.resolve(folderPath)),
      },
    ];
  }

  const items = fs.readdirSync(folderPath);

  const structure = await Promise.all([
    ...items.map(async (item) => {
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
      } else {
        return {
          label: item,
          path: path.resolve(folderPath, item),
          type: "file",
          data: await getCsvSummary(path.resolve(folderPath, item)),
        };
      }
    }),
  ]);

  return structure as TreeNode[];
};
