export default defineEventHandler(async (event: any) => {
  const folder = decodeURIComponent(event.context.params.folder);
  return {};
  // export const getTrainDatas = async (folderName: string): Promise<Source[]> => {
  //   const folderPath = path.resolve(folderName);
  //   const csvFiles = fs
  //     .readdirSync(folderPath, { withFileTypes: true })
  //     .filter((f) => path.extname(f.name).toLowerCase() === ".csv");

  //   return await pipe(
  //     csvFiles,
  //     toAsync,
  //     map(async (csvFile) => {
  //       try {
  //         const parser = fs.createReadStream(path.resolve(csvFile.path, csvFile.name)).pipe(
  //           parse({
  //             delimiter: ",",
  //           }),
  //         );
  //         const records = [];
  //         for await (const record of parser) {
  //           records.push(record);
  //         }
  //         return {
  //           name: csvFile.name,
  //           title: records[0],
  //           data: records.slice(1),
  //         };
  //       } catch (error) {
  //         console.error(`[Parsing CSV Error]:${folderName} ${csvFile.name}`);
  //         throw error;
  //       }
  //     }),
  //     toArray,
  //   );
  // };
});
