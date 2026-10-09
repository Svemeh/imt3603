"""Run in Blender to rebuild the decorative, three-meter vineyard grass strip."""
import bpy
import math
import random
from pathlib import Path

PROJECT = Path(__file__).resolve().parents[1]
rng = random.Random(3603)
collection = bpy.data.collections.new("Corked Vineyard Grass Strip")
bpy.context.scene.collection.children.link(collection)
selected = list(bpy.context.selected_objects)
active = bpy.context.view_layer.objects.active

meadow = bpy.data.materials.new("Vineyard meadow")
meadow.use_nodes = True
bsdf = next(n for n in meadow.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
bsdf.inputs["Roughness"].default_value = 0.95
texture = meadow.node_tree.nodes.new("ShaderNodeTexImage")
texture.image = bpy.data.images.load(str(PROJECT / "models/map/placeables/ground_grass_Ground - olive meadow_albedo.png"), check_existing=True)
meadow.node_tree.links.new(texture.outputs["Color"], bsdf.inputs["Base Color"])

materials = [meadow]
for name, color in [
    ("Grass leaf green", (0.19, 0.34, 0.045, 1)),
    ("Grass spring green", (0.30, 0.46, 0.075, 1)),
    ("Grass sunlit tips", (0.43, 0.55, 0.12, 1)),
]:
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    node = next(n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    node.inputs["Base Color"].default_value = color
    node.inputs["Roughness"].default_value = 0.9
    mat.diffuse_color = color
    mat.use_backface_culling = False
    materials.append(mat)

vertices, faces, face_materials = [], [], []

def polygon(points, material=0):
    start = len(vertices)
    vertices.extend(points)
    faces.append(tuple(range(start, len(vertices))))
    face_materials.append(material)

def edges(t):
    # Periodic edges meet exactly when adjacent tiles form a continuous row.
    a = math.tau * t
    left = -0.69 + 0.09 * math.sin(3*a) + 0.07 * math.sin(11*a)
    right = 0.69 + 0.10 * math.sin(4*a) + 0.06 * math.sin(13*a)
    return left, right

for i in range(72):
    t0, t1 = i / 72, (i + 1) / 72
    l0, r0 = edges(t0)
    l1, r1 = edges(t1)
    y0, y1 = 3*t0 - 1.5, 3*t1 - 1.5
    polygon([(l0,y0,0.016),(r0,y0,0.016),(r1,y1,0.016),(l1,y1,0.016)])

# Broken edge patches make the grass fade into exposed earth without a straight border.
for i in range(36):
    y = rng.uniform(-1.36, 1.36)
    left, right = edges((y+1.5)/3)
    x = (left-rng.uniform(0.025,0.19)) if i % 2 else (right+rng.uniform(0.025,0.19))
    rx, ry = rng.uniform(0.03,0.095), rng.uniform(0.025,0.12)
    polygon([(x+rx*math.cos(j*math.tau/7),y+ry*math.sin(j*math.tau/7),0.018) for j in range(7)])

for i in range(125):
    y = rng.uniform(-1.43,1.43)
    left, right = edges((y+1.5)/3)
    x = rng.uniform(left-0.04,right+0.04)
    for blade in range(rng.randint(3,5)):
        angle = rng.uniform(0,math.tau)
        width, height = rng.uniform(0.016,0.033), rng.uniform(0.065,0.17)
        dx, dy = math.cos(angle), math.sin(angle)
        lean = rng.uniform(0.02,0.08)
        polygon([(x-dy*width,y+dx*width,0.019),
                 (x+dy*width,y-dx*width,0.019),
                 (x+dx*lean,y+dy*lean,0.019+height)],rng.randint(1,3))

mesh = bpy.data.meshes.new("VineyardGrassStripMesh")
mesh.from_pydata(vertices, [], faces)
mesh.update()
for mat in materials:
    mesh.materials.append(mat)
for p, material in zip(mesh.polygons, face_materials):
    p.material_index = material
uv = mesh.uv_layers.new(name="UVMap")
for loop in mesh.loops:
    v = mesh.vertices[loop.vertex_index].co
    uv.data[loop.index].uv = ((v.x+1.5)/3,(v.y+1.5)/3)
obj = bpy.data.objects.new("VineyardGrassStrip", mesh)
collection.objects.link(obj)
for old in bpy.context.selected_objects:
    old.select_set(False)
obj.select_set(True)
bpy.context.view_layer.objects.active = obj
output = PROJECT / "models/map/placeables/grass_strip.glb"
bpy.ops.export_scene.gltf(filepath=str(output), export_format="GLB", use_selection=True)
patch_mesh = mesh.copy()
patch_mesh.name = "WallGrassPatchMesh"
for vertex in patch_mesh.vertices:
    t = min(abs(vertex.co.y) / 1.5, 1.0)
    vertex.co.x *= math.sqrt(max(0.0, 1.0-t**4))
patch = bpy.data.objects.new("WallGrassPatch", patch_mesh)
collection.objects.link(patch)
obj.select_set(False)
patch.select_set(True)
bpy.context.view_layer.objects.active = patch
bpy.ops.export_scene.gltf(filepath=str(PROJECT / "models/map/placeables/grass_patch.glb"), export_format="GLB", use_selection=True)
patch.select_set(False)
for old in selected:
    old.select_set(True)
bpy.context.view_layer.objects.active = active
print(f"Exported {output}: {len(vertices)} vertices, {len(faces)} faces, footprint 3m long")
