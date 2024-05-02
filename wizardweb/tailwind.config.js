/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./components/**/*.{js,vue,ts}",
    "./layouts/**/*.vue",
    "./pages/**/*.vue",
    "./plugins/**/*.{js,ts}",
    "./app.vue",
    "./error.vue",
  ],
  prefix: "tw-",
  theme: {
    screens: {
      xl: { max: "1920px" },
      lg: { max: "1440px" },
      md: { max: "1024px" },
      sm: { max: "600px" },
      xs: { max: "320px" },
      "up-xl": { min: "1921px" },
      "up-lg": { min: "1441px" },
      "up-md": { min: "1025px" },
      "up-sm": { min: "601px" },
      "up-xs": { min: "321px" },
    },
  },
  plugins: [
    ({ addUtilities }) => {
      addUtilities({
        ".text-h1": {
          "font-size": "6rem",
          "font-weight": "300",
          "line-height": "6rem",
          "letter-spacing": "-.01562em",
        },
        ".text-h2": {
          "font-size": "3.75rem",
          "font-weight": "300",
          "line-height": "3.75rem",
          "letter-spacing": "-.00833em",
        },
        ".text-h3": {
          "font-size": "3rem",
          "font-weight": "400",
          "line-height": "3.125rem",
          "letter-spacing": "normal",
        },
        ".text-h4": {
          "font-size": "2.125rem",
          "font-weight": "400",
          "line-height": "2.5rem",
          "letter-spacing": ".00735em",
        },
        ".text-h5": {
          "font-size": "1.5rem",
          "font-weight": "400",
          "line-height": "2rem",
          "letter-spacing": "normal",
        },
        ".text-h6": {
          "font-size": "1.25rem",
          "font-weight": "500",
          "line-height": "2rem",
          "letter-spacing": ".0125em",
        },
        ".text-subtitle1": {
          "font-size": "1rem",
          "font-weight": "400",
          "line-height": "1.75rem",
          "letter-spacing": ".00937em",
        },
        ".text-subtitle2": {
          "font-size": ".875rem",
          "font-weight": "500",
          "line-height": "1.375rem",
          "letter-spacing": ".00714em",
        },
        ".text-body1": {
          "font-size": "1rem",
          "font-weight": "400",
          "line-height": "1.5rem",
          "letter-spacing": ".03125em",
        },
        ".text-body2": {
          "font-size": ".875rem",
          "font-weight": "400",
          "line-height": "1.25rem",
          "letter-spacing": ".01786em",
        },
        ".text-caption": {
          "font-size": ".75rem",
          "font-weight": "400",
          "line-height": "1.25rem",
          "letter-spacing": ".03333em",
        },
        ".text-outline": {
          "font-size": ".75rem",
          "font-weight": "500",
          "line-height": "2rem",
          "letter-spacing": ".16667em",
        },
      });
    },
  ],
};
