components {
  id: "script"
  component: "/main/shot_hub.script"
}
components {
  id: "hit_sound"
  component: "/assets/audio/asteroid_hit.sound"
}
embedded_components {
  id: "shot_factory"
  type: "factory"
  data: "prototype: \"/main/shot.go\"\n"
}
