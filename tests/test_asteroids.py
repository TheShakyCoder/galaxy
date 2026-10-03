"""Run with Python + lupa (Lua 5.1/LuaJIT compatible module). No game server."""
import math
import unittest
from pathlib import Path
from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]


def runtime():
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute("package.path = " + repr(ROOT.as_posix() + '/?.lua;') + " .. package.path")
    return lua


class GeometryTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.lua = runtime()
        cls.geometry = cls.lua.eval('require("main.asteroid_geometry")')

    def test_repeatable_and_unique_for_full_field(self):
        fingerprints = set()
        for i in range(1, 51):
            seed = self.geometry.seed('sol', i)
            a = self.geometry.generate(seed)
            b = self.geometry.generate(seed)
            for name in ('position', 'normal', 'color', 'fragment', 'motion'):
                self.assertEqual(list(a[name].values()), list(b[name].values()))
            fingerprints.add(tuple(a.position.values()))
        self.assertEqual(len(fingerprints), 50)
        self.assertNotEqual(self.geometry.seed('sol', 1), self.geometry.seed('other', 1))

    def test_closed_wedges_bounds_normals_and_winding(self):
        for seed in (1, 77, 104729, 2147483646):
            data = self.geometry.generate(seed)
            p = list(data.position.values())
            n = list(data.normal.values())
            fragments = list(data.fragment.values())
            colors = list(data.color.values())
            count = len(p) // 3
            self.assertEqual(count, 5280)  # 1280 outer + 480 interior triangles
            for key, size in [('normal', 3), ('color', 4), ('fragment', 4), ('motion', 4)]:
                self.assertEqual(len(data[key]), count * size)
                self.assertTrue(all(math.isfinite(x) for x in data[key].values()))
            edges = {}
            for i in range(0, count, 3):
                a, b, c = [tuple(p[j*3:j*3+3]) for j in range(i, i+3)]
                u, v = [b[k]-a[k] for k in range(3)], [c[k]-a[k] for k in range(3)]
                normal = (u[1]*v[2]-u[2]*v[1], u[2]*v[0]-u[0]*v[2], u[0]*v[1]-u[1]*v[0])
                self.assertGreater(sum(x*x for x in normal), 1e-14)
                if colors[i*4+3] == 0:
                    self.assertGreater(sum(normal[k]*a[k] for k in range(3)), 0)
                group = tuple(fragments[i*4:i*4+4])
                for x, y in ((a, b), (b, c), (c, a)):
                    key = (group, tuple(sorted((x, y))))
                    edges.setdefault(key, []).append((x, y))
            for edge in edges.values():
                self.assertEqual(len(edge), 2)
                self.assertEqual(edge[0], tuple(reversed(edge[1])))
            for i in range(count):
                self.assertLessEqual(sum(x*x for x in p[i*3:i*3+3]), 0.250000001)
                self.assertAlmostEqual(sum(x*x for x in n[i*3:i*3+3]), 1, places=7)

    def test_does_not_touch_global_random(self):
        self.lua.execute('math.random = function() error("global RNG used") end; math.randomseed = math.random')
        self.geometry.generate(12)


class LifecycleTests(unittest.TestCase):
    def test_hub_depletion_respawn_scan_and_jump(self):
        lua = runtime()
        lua.execute((ROOT/'tests/asteroid_hub_harness.lua').read_text())

    def test_mesh_lifetime_and_two_second_completion(self):
        lua = runtime()
        lua.execute((ROOT/'tests/asteroid_script_harness.lua').read_text())


if __name__ == '__main__':
    unittest.main()
