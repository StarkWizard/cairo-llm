<script setup lang="ts">
defineProps({
  icon: {
    type: String,
    default: "mdi-home",
  },
  to: {
    type: String,
    default: "/",
  },
});
</script>
<template>
  <q-item :to="to" active-class="bg-secondary" class="hover:tw-bg-gray-700">
    <q-item-section avatar>
      <q-icon :name="icon" class="tw-text-white" />
    </q-item-section>

    <q-item-section class="tw-text-white">
      <slot />
    </q-item-section>
  </q-item>
</template>
