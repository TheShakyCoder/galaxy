components {
  id: "script"
  component: "/main/asteroid_hub.script"
}
components {
  id: "hit_sound"
  component: "/assets/audio/asteroid_hit.sound"
}
components {
  id: "breakup_sound"
  component: "/assets/audio/asteroid_breakup.sound"
}
embedded_components {
  id: "asteroid_factory"
  type: "factory"
  data: "prototype: \"/main/asteroid.go\"\n"
}
embedded_components {
  id: "shot_factory"
  type: "factory"
  data: "prototype: \"/main/shot.go\"\n"
}
