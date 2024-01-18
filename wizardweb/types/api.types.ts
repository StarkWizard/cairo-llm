import { type QTreeNode } from "quasar";

export type CsvFile = {
  name: string;
  columns: [string, string];
  rows: Array<[string, string]>;
  error?: Error;
};

export type CsvSummary = {
  nbRows?: number;
  error?: Error;
};

export interface FileNode extends QTreeNode {
  label: string;
  path: string;
  data?: CsvSummary;
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
