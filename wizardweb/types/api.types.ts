import { type QTreeNode } from "quasar";

export type CsvData = {
  nbRows?: number;
  error?: Error;
};

export interface FileNode extends QTreeNode {
  label: string;
  path: string;
  data?: CsvData;
  type: "file" | "folder";
  updatedAt: string;
}

export interface FolderNode extends QTreeNode {
  label: string;
  path: string;
  children: TreeNode[];
  type: "file" | "folder";
}

export type TreeNode = FileNode | FolderNode;
