<script setup lang="ts">
import { type TreeNode } from "~/types/api.types";
import { useQuasar, QSpinnerBars } from "quasar";

const $q = useQuasar();
$q.loading.show({
  spinner: QSpinnerBars,
  spinnerColor: "white",
  spinnerSize: 140,
  message: "Loading...",
});
const { data, pending } = useAsyncData(async (): Promise<TreeNode[]> => $fetch("/api/train-sources"));
watch(pending, (isPending) => {
  if (!isPending) {
    $q.loading.hide();
  }
});

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

const getRecentDate = (a: string, b: string) => (new Date(a) > new Date(b) ? a : b);
const toDate = (str: string) => {
  return new Date(str).toLocaleString(undefined, {
    year: "numeric",
    month: "short",
    day: "numeric",
  });
};
const getUpdatedAt = (node: TreeNode): string => {
  let updatedAt = new Date(1970, 1, 1).toISOString();

  if (node.type === "file") {
    updatedAt = getRecentDate(updatedAt, node.updatedAt);
    return node.updatedAt;
  }
  if (node.children) {
    for (const child of node.children) {
      if (child.children) {
        updatedAt = getUpdatedAt(child as TreeNode);
      } else {
        updatedAt = getRecentDate(updatedAt, child.updatedAt);
      }
    }
  }
  return updatedAt;
};
</script>
<template>
  <main class="tw-p-4 tw-min-h-[calc(100vh-50px)]" v-if="!$q.loading.isActive">
    <h1 class="tw-text-h3">
      Train sources
      <q-chip icon="mdi-alert" text-color="white" color="negative" v-if="hasError({ children: data } as TreeNode)">
        {{ getTotalErrorFiles({ children: data } as TreeNode) }}
      </q-chip>
      <q-chip icon="mdi-table">
        {{ getTotalRows({ children: data } as TreeNode) }}
      </q-chip>
      <q-chip icon="mdi-calendar">
        {{ toDate(getUpdatedAt({ children: data } as TreeNode)) }}
      </q-chip>
    </h1>

    <section class="tw-my-4" v-if="data">
      <q-tree :nodes="data" node-key="path">
        <template v-slot:default-header="prop">
          <div class="tw-flex tw-items-center tw-flex-wrap">
            <div class="tw-flex tw-items-center">
              <q-icon
                :name="prop.node.type === 'folder' ? 'mdi-folder-outline' : 'mdi-file-table'"
                :color="hasError(prop.node) ? 'negative' : 'secondary'"
                size="28px"
                class="q-mr-sm"
              />

              <span
                v-if="prop.node.type === 'folder'"
                class="tw-font-bold text-primary"
                :class="{ ['!tw-text-red-800']: hasError(prop.node) }"
              >
                {{ prop.node.label }}
              </span>
              <nuxt-link
                v-else
                :to="`/train-sources/${encodeURIComponent(prop.node.path)}`"
                class="tw-font-bold tw-underline"
                :class="{
                  ['tw-text-red-800 hover:tw-text-red-600']: hasError(prop.node),
                  ['hover:tw-text-blue-600']: !hasError(prop.node),
                }"
              >
                {{ prop.node.label }}
              </nuxt-link>

              <q-icon v-if="hasError(prop.node)" name="mdi-alert" class="tw-ml-1" color="negative" />
            </div>

            <div class="tw-flex tw-gap-2 tw-ml-2" :class="{ ['text-negative']: hasError(prop.node) }">
              <div class="tw-flex tw-items-center tw-gap-2">
                <span class="tw-text-gray-500">-</span>
                <span class="tw-text-gray-800">{{ getTotalRows(prop.node) }} rows</span>
                <span class="tw-text-gray-500">-</span>
                <span class="tw-text-gray-800">{{ toDate(getUpdatedAt(prop.node)) }} </span>
              </div>
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
