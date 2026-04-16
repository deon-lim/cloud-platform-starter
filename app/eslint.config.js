export default [
  {
    languageOptions: {
      ecmaVersion: 2021,
      globals: {
        process: "readonly",
        console: "readonly",
        require: "readonly",
        module: "readonly",
        __dirname: "readonly"
      }
    },
    rules: {
      "no-unused-vars": "warn"
    }
  }
];