import path from "path";
import fs from "fs";
import { parse } from "csv-parse";
import type { CsvFile } from "~/types/api.types";

const getCsvData = async (filePath: string): Promise<CsvFile> => {
  try {
    const parser = fs.createReadStream(filePath).pipe(
      parse({
        delimiter: ",",
      }),
    );
    const rows = [];
    for await (const row of parser) {
      rows.push(row);
    }
    return {
      name: path.basename(filePath),
      columns: rows[0],
      rows: rows.slice(1),
    };
  } catch (error) {
    return {
      name: path.basename(filePath),
      columns: ["", ""],
      rows: [],
      error: error as Error,
    };
  }
};

export default defineEventHandler(async (event: any) => {
  const csv = decodeURIComponent(event.context.params.csv);

  return await getCsvData(csv);
});
