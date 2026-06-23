rr_now <- function() format(Sys.time(), tz = "UTC", usetz = TRUE)
rr_abort <- function(message) stop(message, call. = FALSE)
rr_json <- function(x) jsonlite::toJSON(x, auto_unbox = TRUE, null = "null", pretty = FALSE)

rr_scalar <- function(x, default = "") {
  if (is.null(x) || length(x) == 0L) return(default)
  as.character(x[[1L]])
}

rr_uuid_token <- function() digest::digest(uuid::UUIDgenerate(), algo = "sha256", serialize = FALSE)

rr_require_started <- function() {
  if (!isTRUE(.rr$started) || is.null(.rr$listener)) {
    rr_abort("RendezR LAN is not active. Call rr_lan_start() first.")
  }
  invisible(TRUE)
}

rr_require_match <- function() {
  rr_require_started()
  if (!identical(.rr$state, "matched") || is.null(.rr$active_peer)) {
    rr_abort("No active match. Call rr_lan_find() and wait for a peer.")
  }
  invisible(TRUE)
}

rr_add_inbox <- function(direction, body, peer = NULL, at = rr_now(), id = NULL) {
  .rr$inbox[[length(.rr$inbox) + 1L]] <- list(
    direction = as.character(direction),
    at = as.character(at),
    peer = as.character(peer %||% ""),
    body = as.character(body),
    id = as.character(id %||% uuid::UUIDgenerate())
  )
  invisible(NULL)
}

rr_contact_pattern <- function() {
  "(?i)(https?://|www\\.|[[:alnum:]._%+\\-]+@[[:alnum:].\\-]+\\.[[:alpha:]]{2,}|(?:\\+?\\d[ .()\\-]*){8,})"
}

rr_contains_contact_details <- function(text) grepl(rr_contact_pattern(), text, perl = TRUE)

rr_validate_message <- function(text, allow_contact_details = rr_get_config()$allow_contact_details) {
  if (!is.character(text) || length(text) != 1L || is.na(text)) rr_abort("Message must be one non-missing character string.")
  text <- enc2utf8(trimws(text))
  n <- nchar(text, type = "chars", allowNA = FALSE, keepNA = FALSE)
  if (n < 1L) rr_abort("Message is empty.")
  if (n > 600L) rr_abort("Message exceeds the 600-character limit.")
  if (grepl("[[:cntrl:]]", text, perl = TRUE)) rr_abort("Control characters are not allowed in messages.")
  if (!isTRUE(allow_contact_details) && rr_contains_contact_details(text)) {
    rr_abort("This message appears to contain a link, email address, or phone number. Contact details are blocked by default for safety.")
  }
  text
}

rr_local_blocks <- function() unique(rr_get_config()$blocked_peer_ids %||% character())

rr_add_local_block <- function(peer_id) {
  cfg <- rr_get_config()
  cfg$blocked_peer_ids <- unique(c(cfg$blocked_peer_ids %||% character(), as.character(peer_id)))
  rr_set_config(cfg, persist = TRUE)
  invisible(cfg$blocked_peer_ids)
}

rr_console_line <- function(prefix, text) cat(sprintf("[%s] %s %s\n", format(Sys.time(), "%H:%M:%S"), prefix, text))

rr_header <- function(req, name, default = "") {
  headers <- req$HEADERS %||% character()
  if (length(headers) > 0L) {
    idx <- which(tolower(names(headers)) == tolower(name))
    if (length(idx)) return(as.character(headers[[idx[[1L]]]]))
  }
  key <- paste0("HTTP_", toupper(gsub("-", "_", name, fixed = TRUE)))
  as.character(req[[key]] %||% default)
}

rr_json_response <- function(payload, status = 200L) {
  list(
    status = as.integer(status),
    headers = list(
      "Content-Type" = "application/json; charset=utf-8",
      "Cache-Control" = "no-store",
      "X-Content-Type-Options" = "nosniff"
    ),
    body = rr_json(payload)
  )
}

rr_read_json_body <- function(req, limit = 8192L) {
  len <- suppressWarnings(as.integer(req$CONTENT_LENGTH %||% req$HTTP_CONTENT_LENGTH %||% 0L))
  if (is.na(len) || len < 0L || len > limit) rr_abort("Request body is missing or exceeds the allowed size.")
  raw <- req$rook.input$read()
  if (!length(raw)) return(list())
  tryCatch(jsonlite::fromJSON(rawToChar(raw), simplifyVector = FALSE), error = function(e) rr_abort("Invalid JSON request body."))
}

rr_ip_octets <- function(ip) {
  parts <- strsplit(as.character(ip), ".", fixed = TRUE)[[1L]]
  if (length(parts) != 4L || any(!grepl("^[0-9]{1,3}$", parts))) return(NULL)
  nums <- suppressWarnings(as.integer(parts))
  if (any(is.na(nums) | nums < 0L | nums > 255L)) return(NULL)
  nums
}

rr_is_private_ipv4 <- function(ip) {
  x <- rr_ip_octets(ip)
  if (is.null(x)) return(FALSE)
  identical(x[[1L]], 10L) ||
    (identical(x[[1L]], 172L) && x[[2L]] >= 16L && x[[2L]] <= 31L) ||
    (identical(x[[1L]], 192L) && identical(x[[2L]], 168L)) ||
    identical(as.character(ip), "127.0.0.1")
}

rr_ip_to_int <- function(ip) {
  x <- rr_ip_octets(ip)
  if (is.null(x)) return(NA_real_)
  sum(as.numeric(x) * c(256^3, 256^2, 256, 1))
}

rr_parse_cidr <- function(cidr) {
  bits <- strsplit(as.character(cidr), "/", fixed = TRUE)[[1L]]
  if (length(bits) != 2L) rr_abort("CIDR must use notation such as '192.168.1.0/24'.")
  ip <- bits[[1L]]
  prefix <- suppressWarnings(as.integer(bits[[2L]]))
  if (!rr_is_private_ipv4(ip) || is.na(prefix) || prefix < 16L || prefix > 30L) {
    rr_abort("Only private IPv4 CIDRs with a prefix between /16 and /30 are accepted.")
  }
  ip_int <- rr_ip_to_int(ip)
  block <- 2^(32 - prefix)
  network <- floor(ip_int / block) * block
  list(ip = ip, prefix = prefix, network = network, block = block, cidr = paste0(rr_int_to_ip(network), "/", prefix))
}

rr_int_to_ip <- function(value) {
  value <- as.numeric(value)
  a <- floor(value / 256^3) %% 256
  b <- floor(value / 256^2) %% 256
  c <- floor(value / 256) %% 256
  d <- value %% 256
  paste(as.integer(c(a, b, c, d)), collapse = ".")
}

rr_ip_in_cidr <- function(ip, cidr) {
  parsed <- if (is.character(cidr)) rr_parse_cidr(cidr) else cidr
  x <- rr_ip_to_int(ip)
  if (is.na(x)) return(FALSE)
  x >= parsed$network && x < (parsed$network + parsed$block)
}

rr_cidr_hosts <- function(cidr, max_hosts = 254L) {
  p <- rr_parse_cidr(cidr)
  available <- as.integer(p$block - 2)
  if (available < 1L) return(character())
  if (available > as.integer(max_hosts)) {
    rr_abort(paste0("The selected subnet contains ", available, " hosts. For safety, narrow it to /24 or smaller; RendezR LAN will not scan it automatically."))
  }
  vapply(seq.int(p$network + 1, p$network + p$block - 2), rr_int_to_ip, character(1))
}

rr_guess_ipv4_addresses <- function() {
  os <- Sys.info()[["sysname"]] %||% ""
  lines <- character()
  if (identical(os, "Windows")) {
    lines <- tryCatch(system2("ipconfig", stdout = TRUE, stderr = TRUE), error = function(e) character())
  } else if (identical(os, "Darwin")) {
    lines <- tryCatch(system2("ifconfig", stdout = TRUE, stderr = TRUE), error = function(e) character())
  } else {
    lines <- tryCatch(system2("ip", c("-o", "-4", "addr", "show"), stdout = TRUE, stderr = TRUE), error = function(e) character())
    if (!length(lines)) lines <- tryCatch(system2("hostname", "-I", stdout = TRUE, stderr = TRUE), error = function(e) character())
  }
  matches <- unlist(regmatches(lines, gregexpr("(?<![0-9])(?:[0-9]{1,3}\\.){3}[0-9]{1,3}(?![0-9])", lines, perl = TRUE)), use.names = FALSE)
  unique(matches[vapply(matches, rr_is_private_ipv4, logical(1)) & matches != "127.0.0.1"])
}

rr_choose_ipv4 <- function(address = NULL) {
  if (!is.null(address)) {
    address <- as.character(address)[[1L]]
    if (!rr_is_private_ipv4(address) || address == "127.0.0.1") rr_abort("address must be one private non-loopback IPv4 address.")
    return(address)
  }
  ips <- rr_guess_ipv4_addresses()
  if (!length(ips)) rr_abort("No private IPv4 address was found. Connect to a local network or pass address = '192.168.x.y' explicitly.")
  ips[[1L]]
}

rr_default_cidr <- function(ip) {
  x <- rr_ip_octets(ip)
  paste0(paste(x[1:3], collapse = "."), ".0/24")
}

rr_http_handle <- function(timeout_ms = 700L) {
  h <- curl::new_handle()
  curl::handle_setopt(h,
    timeout_ms = as.integer(timeout_ms),
    connecttimeout_ms = as.integer(timeout_ms),
    proxy = "",
    followlocation = FALSE,
    fresh_connect = TRUE,
    forbid_reuse = TRUE
  )
  h
}

rr_http_get_json <- function(url, timeout_ms = 700L) {
  h <- rr_http_handle(timeout_ms)
  out <- curl::curl_fetch_memory(url, handle = h)
  if (!identical(as.integer(out$status_code), 200L)) rr_abort(paste0("Local peer returned HTTP ", out$status_code, "."))
  jsonlite::fromJSON(rawToChar(out$content), simplifyVector = FALSE)
}

rr_http_post_json <- function(url, payload, timeout_ms = 1000L) {
  h <- rr_http_handle(timeout_ms)
  curl::handle_setopt(h, customrequest = "POST", postfields = rr_json(payload))
  curl::handle_setheaders(h, "Content-Type" = "application/json", "X-RendezR-Protocol" = rr_protocol_version())
  out <- curl::curl_fetch_memory(url, handle = h)
  if (!identical(as.integer(out$status_code), 200L)) rr_abort(paste0("Local peer returned HTTP ", out$status_code, "."))
  jsonlite::fromJSON(rawToChar(out$content), simplifyVector = FALSE)
}

rr_peer_url <- function(address, port, path) sprintf("http://%s:%d%s", address, as.integer(port), path)
