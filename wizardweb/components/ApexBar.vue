<script setup>
import { getCssVar } from "quasar";

const props = defineProps({
  title: {
    type: String,
    default: undefined,
  },
  height: {
    type: String,
    default: "300",
  },
  values: {
    type: Array,
    default: ["100"],
  },
  labels: {
    type: Array,
    default: ["label"],
  },
});
const options = computed(() => ({
  title: {
    text: props.title,
    align: "left",
  },
  chart: {
    id: "apex-bar",
    toolbar: {
      show: false,
    },
  },
  colors: [getCssVar("secondary"), getCssVar("warning"), getCssVar("negative")],
  xaxis: {
    categories: props.labels,
  },
  yaxis: {
    // max: 1000,
  },
  plotOptions: {
    bar: {
      horizontal: true,
      columnWidth: "55%",
      endingShape: "rounded",
    },
  },
}));

const series = computed(() => [
  {
    name: "value",
    data: props.values,
  },
]);
</script>

<template>
  <div
    style="
       {
        minHeight: `${height}px`
      }
    "
  >
    <ClientOnly>
      <apexchart :height="height" type="bar" :options="options" :series="series"></apexchart>
    </ClientOnly>
  </div>
</template>
