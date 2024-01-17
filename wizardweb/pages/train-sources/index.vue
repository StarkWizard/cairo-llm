<script setup lang="ts">
import { type TreeNode } from "~/types/api.types";
import AutoCounter from "vue3-autocounter";

const { data } = useAsyncData(async (): Promise<TreeNode[]> => $fetch("/api/train-sources"));
const hasError = (node: TreeNode): boolean => {
  if (!node.children) return !!node.data?.error;

  for (const child of node.children) {
    if (child.children) return hasError(child as TreeNode);
    if (child.data?.error) return true;
  }
  return false;
};
const getTotalRows = (node: TreeNode): number => {
  let total = 0;

  if (node.data?.nbRows) {
    total += node.data?.nbRows;
  }
  if (node.children) {
    for (const child of node.children) {
      if (child.children) {
        total += getTotalRows(child as TreeNode);
      } else {
        total += child.data?.nbRows || 0;
      }
    }
  }
  return total;
};
const getTotalErrorFiles = (node: TreeNode): number => {
  let total = 0;
  if (node.data?.error) {
    total += 1;
  }
  if (node.children) {
    for (const child of node.children) {
      if (child.children) {
        total += getTotalErrorFiles(child as TreeNode);
      } else {
        total += child.data?.error ? 1 : 0;
      }
    }
  }
  return total;
};
</script>
<template>
  <main class="tw-p-4 tw-min-h-[calc(100vh-50px)]">
    <h1 class="tw-text-h3">
      Train sources
      <q-chip icon="mdi-table">
        <AutoCounter v-if="data" :duration="2" :end-amount="getTotalRows({ children: data } as TreeNode)" />
      </q-chip>
      <q-chip icon="mdi-alert" text-color="white" color="negative" v-if="hasError({ children: data } as TreeNode)">
        {{ getTotalErrorFiles({ children: data } as TreeNode) }}
      </q-chip>
    </h1>

    <section class="tw-my-4" v-if="data">
      <q-tree :nodes="data" node-key="path">
        <template v-slot:default-header="prop">
          <div class="row items-center">
            <q-icon
              :name="prop.node.type === 'folder' ? 'mdi-folder-outline' : 'mdi-file-table'"
              :color="hasError(prop.node) ? 'negative' : 'secondary'"
              size="28px"
              class="q-mr-sm"
            />
            <div class="text-weight-bold text-primary" :class="{ ['text-negative']: hasError(prop.node) }">
              {{ prop.node.label }}
              <span v-if="hasError(prop.node)">
                <q-icon name="mdi-alert" color="negative" /> {{ prop.node.data?.nbRows }}
              </span>
              <span class="tw-text-gray-400"> - {{ getTotalRows(prop.node) }} rows </span>
            </div>
          </div>
        </template>

        <template v-slot:default-body="prop">
          <div v-if="prop.node.data?.error" class="bg-primary tw-p-2 tw-mt-1 tw-mb-2">
            <span class="tw-text-white">{{ prop.node.data.error }}</span>
          </div>
        </template>
      </q-tree>
    </section>
  </main>
</template>

<style module lang="scss">
.gridContainer {
  grid-template-columns: repeat(auto-fill, minmax(30%, auto));

  @media screen and (max-width: 1280px) {
    grid-template-columns: repeat(auto-fill, minmax(45%, auto));
  }
  @media screen and (max-width: 700px) {
    grid-template-columns: repeat(auto-fill, minmax(100%, auto));
  }
}
</style>
