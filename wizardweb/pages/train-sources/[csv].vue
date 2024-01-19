<script setup lang="ts">
import type { CsvFile } from "~/types/api.types";
import { useQuasar, QSpinnerBars } from "quasar";

const route = useRoute();
const $q = useQuasar();
$q.loading.show({
  spinner: QSpinnerBars,
  spinnerColor: "white",
  spinnerSize: 140,
  message: "Loading...",
  delay: 500,
});
const { data, pending } = useAsyncData(
  async (): Promise<CsvFile> => $fetch(`/api/train-sources/${encodeURIComponent(route.params.csv as string)}`),
);

watch(pending, (isPending) => {
  if (!isPending) {
    $q.loading.hide();
  }
});

const getColumns = (arr: [q: string, a: string]) => {
  return arr.map((a) => ({ name: a, label: a, field: a }));
};
const getRows = (arr: Array<[q: string, a: string]>) => {
  return arr.map((a, idx) => {
    return {
      question: a[0]?.trim(),
      answer: a[1]?.trim(),
    };
  });
};
</script>
<template>
  <main class="tw-p-4 tw-min-h-[calc(100vh-50px)]">
    <template v-if="data">
      <q-breadcrumbs class="tw-text-[20px] tw-mb-4" active-color="secondary">
        <q-breadcrumbs-el label="train-sources" icon="mdi-folder" to="/train-sources/" class="hover:tw-text-blue-600" />
        <q-breadcrumbs-el :label="data.name" icon="mdi-file-table" />
      </q-breadcrumbs>

      <section v-if="data.error">
        <div class="bg-primary tw-px-4 tw-py-6 tw-mt-1">
          <p class="tw-text-h5 tw-text-red-500 tw-mb-4">Error</p>
          <pre class="tw-text-white">{{ data.error }}</pre>
        </div>
      </section>
      <section v-else>
        <template v-if="!$q.loading.isActive">
          <q-table
            :columns="getColumns(data.columns)"
            :rows="getRows(data.rows)"
            virtual-scroll
            style="height: calc(100vh - 128px)"
          >
            <template v-slot:body="props">
              <q-tr :props="props">
                <q-td v-for="col in props.cols" :key="col.name" :props="props" class="tw-text-left">
                  <pre class="tw-h-full tw-w-full tw-text-pretty"
                    >{{ col.value }}
                  </pre>
                </q-td>
              </q-tr>
            </template>
          </q-table>
        </template>
      </section>
    </template>
    <template v-else>
      <h1>ERROR</h1>
    </template>
  </main>
</template>
