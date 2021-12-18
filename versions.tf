terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
      version = "= 0.6.11"
    }
  }
  required_version = ">= 0.14"
}
