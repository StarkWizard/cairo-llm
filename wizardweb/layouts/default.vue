<script setup>
const leftDrawerOpen = ref(false);
const toggleLeftDrawer = () => {
  leftDrawerOpen.value = !leftDrawerOpen.value;
};
</script>
<template>
  <q-layout view="lHh lpR fFf">
    <q-header elevated>
      <q-toolbar class="no-wrap">
        <div class="col row">
          <q-btn flat dense round icon="menu" aria-label="Menu" @click="toggleLeftDrawer" />

          <q-toolbar-title> Cairo-LLM </q-toolbar-title>
        </div>

        <q-btn>
          <a href="https://github.com/StarkWizard/cairo-llm" target="_blank" class="tw-flex tw-items-center tw-gap-2">
            <q-icon name="mdi-github" size="sm" />
            Github
          </a>
        </q-btn>
      </q-toolbar>
    </q-header>

    <q-drawer v-model="leftDrawerOpen" show-if-above class="bg-primary scrollbar">
      <TheDrawerNavbar />
    </q-drawer>

    <q-page-container>
      <slot></slot>
    </q-page-container>
  </q-layout>
</template>
