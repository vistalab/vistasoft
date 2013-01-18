#!/usr/bin/env python
import Tkinter
import math, os, sys
import vtk
import vtk.tk
from vtk.tk.vtkTkRenderWidget import *

# Make a root window
root = Tkinter.Tk() 

# Add a vtkTkRenderWidget
pane = vtkTkRenderWidget(root,width=400,height=400)
pane.pack(expand='true',fill='both')

# Get the render window from the widget
renWin = pane.GetRenderWindow()

# Next, do the VTK stuff
ren = vtk.vtkRenderer()
renWin.AddRenderer(ren)
cone = vtk.vtkConeSource()
cone.SetResolution(64)
coneMapper = vtk.vtkPolyDataMapper()
coneMapper.SetInput(cone.GetOutput())
coneActor = vtk.vtkActor()
coneActor.SetMapper(coneMapper)
ren.AddActor(coneActor)

# Make a quit button
def quit():
    root.destroy()

button = Tkinter.Button(text="Quit",command=quit)
button.pack(expand='true',fill='x')

# start up the event loop
root.mainloop()
