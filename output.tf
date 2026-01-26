output "workload_a_url" {
  value = azurerm_linux_web_app.workload_a.default_site_hostname
}

output "workload_b_url" {
  value = azurerm_linux_web_app.workload_b.default_site_hostname
}
