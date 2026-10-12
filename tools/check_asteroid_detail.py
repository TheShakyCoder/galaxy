"""Report old/new CPU generation and exact mesh costs. Not a GPU benchmark."""
from pathlib import Path
import hashlib,json,time,statistics
from lupa.lua51 import LuaRuntime
ROOT=Path(__file__).resolve().parents[1]
lua=LuaRuntime(unpack_returned_tuples=True)
lua.execute('package.path='+repr(ROOT.as_posix()+'/?.lua;')+'..package.path')
old=lua.eval('require("tests.asteroid_preview.baseline.geometry")');new=lua.eval('require("main.asteroid_geometry")')
benchmark=lua.eval('function(g,count) for i=1,count do local m=g.generate(g.seed("sol",i)); assert(#m.position==15840) end end')
timings={}
for label,module in [('original',old),('detail',new)]:
    benchmark(module,1)
    rows={}
    for count in (50,100):
        values=[]
        for _ in range(3):
            lua.execute('collectgarbage("collect")');start=time.perf_counter();benchmark(module,count);values.append(time.perf_counter()-start)
        rows[str(count)]=dict(median_seconds=statistics.median(values),samples_seconds=values)
    timings[label]=rows
result=dict(base='6d1f0a546d484ebf2a67862e4c2d52c51a953190',vertices_per_rock=5280,triangles_per_rock=1760,floats_per_vertex=18,mesh_bytes_per_rock=380160,mesh_bytes_50=19008000,mesh_bytes_100=38016000,mesh_memory_increase_bytes=0,draws_per_rock=1,shared_texture_dimensions=[256,256],shared_texture_rgba8_bytes=262144,shared_texture_source_bytes=(ROOT/'assets/models/asteroids/surface.png').stat().st_size,texture_samples_per_fragment=3,cpu_generation=timings,notes=['CPU timing is local Python-embedded Lua 5.1, excluding Defold buffer upload and GPU rendering. It is not browser frame time.','50 is the default field; Sol and Polaris have 100 rocks.','No extra debris objects, particles or draw calls; no distance LOD in this pass.','Baseline snapshots are preview-only copies from the base commit, never production dependencies.'])
out=ROOT/'artifacts/asteroids/detail';out.mkdir(parents=True,exist_ok=True)
(out/'validation.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result,indent=2))
