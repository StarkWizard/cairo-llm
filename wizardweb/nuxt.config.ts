// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  devtools: { enabled: true },
  css: ["~/assets/main.css"],
  modules: ["nuxt-quasar-ui"],
  quasar: {
    sassVariables: "assets/quasar.scss",
    config: {
      dark: false,
    },
    extras: {
      fontIcons: ["mdi-v7"],
    },
    plugins: [],
  },
  postcss: {
    plugins: {
      tailwindcss: {},
      autoprefixer: {},
    },
  },
});
