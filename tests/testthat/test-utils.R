test_that("CIDR parsing remains private and bounded", {
  expect_equal(rendezr:::rr_parse_cidr("192.168.12.77/24")$cidr, "192.168.12.0/24")
  expect_true(rendezr:::rr_ip_in_cidr("192.168.12.42", "192.168.12.0/24"))
  expect_false(rendezr:::rr_ip_in_cidr("192.168.13.42", "192.168.12.0/24"))
  expect_error(rendezr:::rr_parse_cidr("8.8.8.0/24"), "Only private")
  expect_error(rendezr:::rr_cidr_hosts("10.1.0.0/16"), "narrow")
})

test_that("message validation blocks likely contact details by default", {
  expect_equal(rendezr:::rr_validate_message("Hello there", FALSE), "Hello there")
  expect_error(rendezr:::rr_validate_message("https://example.org", FALSE), "contact")
  expect_error(rendezr:::rr_validate_message("test@example.org", FALSE), "contact")
})

test_that("room and port validation are strict", {
  expect_equal(rendezr:::rr_validate_room(" Bayesian Methods "), "bayesian-methods")
  expect_equal(rendezr:::rr_validate_port(47831), 47831L)
  expect_error(rendezr:::rr_validate_port(80), "between")
})
