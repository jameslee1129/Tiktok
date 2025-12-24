import { getProductsRaw } from "./products-raw.mjs";

const result = await getProductsRaw({
  cookie: "REAL_COOKIE_STRING_HERE",
  oecSellerId: "7496020242935155064",
  baseUrl: "https://seller-us.tiktok.com",
  fp: "verify_mgtck5di_g1D3MIo1_jzhg_4B1L_AWG5_v0hAcN4BqwS3",
  timezoneOffset: -28800,
  startDate: "2025-12-23",
  endDate: "2025-12-24",
  region: "US",
  page: 0,
});

console.log("FETCH DONE");
