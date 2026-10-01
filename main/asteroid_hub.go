components {
  id: "script"
  component: "/main/asteroid_hub.script"
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
