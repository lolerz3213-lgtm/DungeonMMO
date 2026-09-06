import bpy, math, os
from mathutils import Vector

OUT = os.path.dirname(os.path.abspath(__file__))
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)

def material(name, color, roughness):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*color, 1)
    m.use_nodes = True
    bs = m.node_tree.nodes.get('Principled BSDF')
    bs.inputs['Base Color'].default_value = (*color, 1)
    bs.inputs['Roughness'].default_value = roughness
    noise = m.node_tree.nodes.new('ShaderNodeTexNoise')
    noise.inputs['Scale'].default_value = 35
    bump = m.node_tree.nodes.new('ShaderNodeBump')
    bump.inputs['Strength'].default_value = .16
    bump.inputs['Distance'].default_value = .025
    m.node_tree.links.new(noise.outputs['Fac'], bump.inputs['Height'])
    m.node_tree.links.new(bump.outputs['Normal'], bs.inputs['Normal'])
    return m

stone = material('Warm weathered limestone', (.39,.34,.26), .83)
trim = material('Carved pale limestone', (.53,.47,.36), .76)
dark = material('Inset slate', (.10,.155,.16), .75)
parts = []

def finish(obj, mat, bevel=.02):
    obj.data.materials.append(mat)
    if bevel:
        mod = obj.modifiers.new('Soft carved edges', 'BEVEL')
        mod.width = bevel
        mod.segments = 3
        mod = obj.modifiers.new('Weighted corner normals', 'WEIGHTED_NORMAL')
        mod.keep_sharp = True
        mod.weight = 50
    parts.append(obj)
    return obj

# An eight-point chamfered square, swept through a hand-designed moulding profile.
outline = [(-1,-.73),(-.73,-1),(.73,-1),(1,-.73),(1,.73),(.73,1),(-.73,1),(-1,.73)]
def profile(name, rings, mat, bevel=.018):
    verts = [(x*r,y*r,z) for z,r in rings for x,y in outline]
    faces = [tuple(reversed(range(8)))]
    for j in range(len(rings)-1):
        for i in range(8):
            a=j*8+i; b=j*8+(i+1)%8
            faces.append((a,b,b+8,a+8))
    faces.append(tuple((len(rings)-1)*8+i for i in range(8)))
    mesh=bpy.data.meshes.new(name)
    mesh.from_pydata(verts,[],faces); mesh.update()
    obj=bpy.data.objects.new(name,mesh); bpy.context.collection.objects.link(obj)
    return finish(obj,mat,bevel)

profile('Continuous sculpted pedestal', [(0,.86),(.12,.86),(.18,.79),(.24,.79),(.27,.71),(.35,.69),(.46,.57),(.52,.55),(.59,.55),(.64,.49)],trim)
profile('Entasis shaft',[(.57,.455),(.76,.455),(1.15,.44),(2.4,.39),(3.48,.36),(3.63,.38)],stone,.025)
profile('Foot collar',[(.61,.49),(.69,.49),(.73,.46)],dark,.01)
profile('Neck astragal',[(3.43,.39),(3.48,.435),(3.57,.435),(3.63,.39)],trim,.018)
profile('Flared carved capital',[(3.61,.39),(3.73,.42),(3.95,.59),(4.04,.67),(4.13,.67),(4.18,.73),(4.32,.73),(4.37,.69)],trim)

# Raised pointed arch ribs on each face, plus a narrow recessed-looking slate lancet.
def face_prism(name, polygon, depth, angle, mat, bevel=.012):
    verts=[]
    for offset in [0,depth]:
        for x,z in polygon:
            r=.455-(z-.76)*.035
            y=-r-offset
            verts.append((x*math.cos(angle)-y*math.sin(angle),x*math.sin(angle)+y*math.cos(angle),z))
    n=len(polygon)
    faces=[tuple(reversed(range(n))),tuple(range(n,2*n))]
    faces += [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    mesh=bpy.data.meshes.new(name); mesh.from_pydata(verts,[],faces); mesh.update()
    obj=bpy.data.objects.new(name,mesh); bpy.context.collection.objects.link(obj)
    return finish(obj,mat,bevel)

for k in range(4):
    a=k*math.pi/2
    face_prism('Slate lancet %d'%k,[(-.10,1.02),(.10,1.02),(.10,2.92),(0,3.17),(-.10,2.92)],.016,a,dark,.009)
    for s in [-1,1]:
        poly=[(s*.14,.93),(s*.205,1.05),(s*.205,2.92),(0,3.30),(0,3.20),(s*.14,2.88)]
        face_prism('Pointed arch carved rib',poly,.045,a,trim,.014)
    face_prism('Diamond foot ornament',[(-.11,1.12),(0,.92),(.11,1.12),(0,1.32)],.065,a,trim)
    # Leaf-like tapered reliefs follow the outward flare of the capital.
    poly=[(-.055,3.67),(.055,3.67),(.17,3.95),(0,4.07),(-.17,3.95)]
    obj=face_prism('Capital acanthus shield',poly,.048,a,stone)
    for v in obj.data.vertices:
        z=v.co.z
        d=max(0,z-3.67)*.70
        v.co.x += math.sin(a)*d
        v.co.y -= math.cos(a)*d

# Apply modifiers, unify asset, and keep its origin at floor centre.
bpy.ops.object.select_all(action='DESELECT')
for obj in parts:
    bpy.context.view_layer.objects.active=obj
    for mod in list(obj.modifiers):
        bpy.ops.object.modifier_apply(modifier=mod.name)
    obj.select_set(True)
bpy.context.view_layer.objects.active=parts[0]
bpy.ops.object.join()
pillar=bpy.context.object; pillar.name='FantasyStonePillar'
bpy.context.scene.cursor.location=(0,0,0)
bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
pillar.data.calc_loop_triangles()
print('PILLAR_TRIANGLES:',len(pillar.data.loop_triangles))
pillar['scale_note']='4.37 units tall; floor-centred origin; import scale can be adjusted in Roblox.'
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT,'FantasyStonePillar.glb'),export_format='GLB',use_selection=True)

floor=material('Studio floor',(.055,.075,.082),.9)
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.015))
bpy.context.object.name='Preview ground'; bpy.context.object.data.materials.append(floor)
def aim(obj, point): obj.rotation_euler=(Vector(point)-obj.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add(location=(6.3,-9,6))
camera=bpy.context.object; aim(camera,(0,0,2.13)); camera.data.type='ORTHO'; camera.data.ortho_scale=5.9
bpy.context.scene.camera=camera
for name,loc,power,size,color in [('Large warm key',(3,-4,7),1000,4,(1,.86,.69)),('Cool fill',(-4,-2,4),650,3,(.64,.79,1)),('Rim',(1,4,6),1250,3,(1,.9,.72))]:
    bpy.ops.object.light_add(type='AREA',location=loc)
    light=bpy.context.object; light.name=name; light.data.energy=power; light.data.shape='DISK'; light.data.size=size; light.data.color=color; aim(light,(0,0,2))
scene=bpy.context.scene
scene.render.engine='CYCLES'; scene.cycles.samples=48
scene.cycles.use_denoising=True
scene.world.color=(.18,.18,.18)
scene.render.resolution_x=900; scene.render.resolution_y=1100; scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG'
scene.render.filepath=os.path.join(OUT,'FantasyStonePillar_preview.png')
scene.unit_settings.system='METRIC'
bpy.ops.object.select_all(action='DESELECT'); pillar.select_set(True); bpy.context.view_layer.objects.active=pillar
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT,'FantasyStonePillar.blend'))
bpy.ops.render.render(write_still=True)
