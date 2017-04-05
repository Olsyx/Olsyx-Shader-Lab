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

### Texture Overlap
A shader that will take an extra albedo texture, an extra normal map and a mask, overlapping them over the object over time taking. The mask
tells the shader where to overlap, using the red channel as reference.
The variation over time is optional and can be animated if needed. 
Features two modes for the albedo: 
- Full: Overlap the texture as a cutout. This means that, by the end of the cycle, only one of the two textures exists at a certain fragment.
- Multiply: Blends both textures.
An script Scorch exemplifies how to animate the time variation.
Uses Standard as a base. Has its own GUI Script. 

![Texture Overlap Screenshot](http://i.imgur.com/vqwF2wr.mp4)

## License
Everything in this project would be under the [LGPL-3.0 license](https://tldrlegal.com/license/gnu-lesser-general-public-license-v3-(lgpl-3)#summary). 
