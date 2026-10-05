components {
  id: "script"
  component: "/main/asteroid_hub.script"
}
components {
  id: "breakup_sound"
  component: "/assets/audio/asteroid_breakup.sound"
}
components {
  id: "scan_sound"
  component: "/assets/audio/scan.sound"
}
embedded_components {
  id: "asteroid_factory"
  type: "factory"
  data: "prototype: \"/main/asteroid.go\"\n"
}
