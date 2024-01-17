import { getFolderStructure, ROOT_FOLDER_PATH } from "./_utils";

export default defineEventHandler(async (event) => {
  const folderStructure = await getFolderStructure(ROOT_FOLDER_PATH);
  return folderStructure;
});
