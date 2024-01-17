<script setup lang="ts">
const route = useRoute();
const { data, error } = useAsyncData(
  async (): Promise<Source[]> => $fetch(`/api/train-sources/${encodeURIComponent(route.params.folder)}`),
);
const getColumns = (arr: [q: string, a: string]) => {
  return [
    {
      name: "index",
      label: "#",
      field: "index",
    },
    ...arr.map((a) => ({ name: a, label: a, field: a })),
  ];
};
const getRows = (arr: Array<[q: string, a: string]>) => {
  return arr.map((a, idx) => ({
    index: idx + 1,
    question: a[0],
    answer: a[1],
  }));
};
</script>
<template>
  <main class="tw-p-4 tw-min-h-[calc(100vh-50px)]">
    <section v-for="source in data">
      <q-table bordered grid :title="source.name" :columns="getColumns(source.title)" :rows="getRows(source.data)" />
    </section>
  </main>
</template>
