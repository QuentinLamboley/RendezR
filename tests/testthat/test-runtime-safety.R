test_that("package runtime starts inert", {
  rendezr:::rr_reset_runtime(keep_config = TRUE)
  st <- rr_status()
  expect_false(st$active)
  expect_equal(st$state, "offline")
})

test_that("terms must be accepted before LAN start", {
  cfg <- rendezr:::rr_get_config()
  old <- cfg$accepted_terms_version
  cfg$accepted_terms_version <- NULL
  rendezr:::rr_set_config(cfg, persist = FALSE)
  expect_error(rr_lan_start(port = 47831), "Participation rules")
  cfg$accepted_terms_version <- old
  rendezr:::rr_set_config(cfg, persist = FALSE)
})
