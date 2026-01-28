output "internal_lob_url" {
  value = azurerm_linux_web_app.internal_lob.default_hostname
}

output "customer_portal_url" {
  value = azurerm_linux_web_app.customer_portal.default_hostname
}
