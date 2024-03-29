// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  devtools: { enabled: true },
  css: ["~/assets/main.css"],
  ssr: false,
  modules: ["nuxt-quasar-ui"],
  quasar: {
    sassVariables: "assets/quasar.scss",
    config: {
      dark: false,
    },
    extras: {
      fontIcons: ["mdi-v7"],
    },
    plugins: ["Loading"],
  },
  postcss: {
    plugins: {
      tailwindcss: {},
      autoprefixer: {},
    },
  },
});
