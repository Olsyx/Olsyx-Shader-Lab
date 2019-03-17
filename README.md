# Olsyx's Shader Lab
This is a Unity project dedicated to create and experiment with shaders. Just 

### What / Who is Olsyx?
That would be me ;) It is another one of my nicknames, one I'm hopeful to completely migrate to at some point.

### Are these shaders completely programmed by you? How did you learn?
Actually, no, not everything on these shaders is mine. The base for my shaders, OlsyxLightning, has been programmed by following 
[CatlikeCoding's Tutorials](http://catlikecoding.com/unity/tutorials/), especifically the Rendering Section. This is how I have learnt
most of what I know about shaders for now, and the base for everything I will do. I expect my hard work will eventually change most, 
if not all, of the code explained there, but it seems only fair to credit CatlikeCoding for introducing me to this world.

## Shaders
### Standard
A Standard shader. It works for both forward and deferred pass, is able to render shadows and reflect both multiple indirect and direct lights
as well as their cookies. It supports Opaque, Cutout, Fade and Transparent objects. Largely based in [CatlikeCoding's Tutorials](http://catlikecoding.com/unity/tutorials/) 
with some tweaks of my own. Has its own GUI Script.

### Crazy Parrot
My first shader. I love Crazy Parrot  and some colleages challenged me to create a shader based on it.
It takes an extra color to which the object will lerp over time. This variation is optional and can be animated through code, although a slider
is not provided for visualization.
Uses Standard as a base. Has its own GUI Script. 

![CrazyParrot](http://cultofthepartyparrot.com/parrots/hd/parrot.gif)

### Transition Shader
![TransitionShader](/Screenshots/TransitionShaders.PNG)

[Click here to see a GIF](https://twitter.com/_Darkatom_/status/852043636065787904)

#### · Legend
Left-to-Right / Top-to-Bottom:
1. Simple Smoothness & Metallic Transition
2. Full Texture Overlap: (a) Full Transition, (b) Multiplied Albedos
3. Masked Texture Overlap + Normals (also allows for Full and Multiplied Albedos)
4. Dissolve
5. Dissolve + Colored Edges (also allows for not colored edges)
6. Texture Overlap + Edges: (a) Full Transition, (b) Multiplied Albedos (also allows for not colored edges)

#### · Features
This shader will transition Albedo, Normal, Smoothness, Metallic and Occlusion Maps. For this it features a Transition Value slider that can be activated with the shader's standard variation `(abs(sin(Time*Speed))`, where Speed is set by the user. When not using the standard variation, the transition value will remain static unless animated through an script.
It also features three optional effects: 
- Full/Multiply Albedos: How they will look after transitioning.
- Dissolve (toggle): Will make the object dissappear over Transition Value. Hides all maps on inspector except Mask.
- Use Color Ramp (toggle): Will enable Edge Transition. Makes an additional map appear, Color Ramp, and a slider to choose how much color amount (edge size) must be applied. The Color Ramp is entirely optional.

#### · The Mask Map
The _Mask_ map is always visible in the inspector, as it is core to the shader. Using the three RGB channels, it tells the shader where do the transitions happen. This is true for all maps mentioned above. The _Mask_, however, is optional for everything except the Dissolve and Edge features, which need it. Without it, the object will just dissapear without making a transition.

#### · Lighting, shadows and GUI
The Transition Shader uses Olsyx's Standard as a base (that is, both Lighting and Shadows _cgincs_) and features its own Olsyx's Transition _cginc_. This means it is _also_ able to carry out all the mentioned above for transparent, fade and cutout objects.
It also features its own GUI Script. 

#### · Efficiency
It seems to run very smoothly, although further testing is needed. The bottle neck for this shader is actually the GUI. Setting a feature can freeze the program for as long as two seconds.

## License
Everything in this project would be under the [LGPL-3.0 license](https://tldrlegal.com/license/gnu-lesser-general-public-license-v3-(lgpl-3)#summary). It is free to use and learn from it, and you can also use it in your projects (commercial included) as long as you credit me as the source =) 
