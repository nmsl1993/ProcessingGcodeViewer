import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;


import javax.swing.JFileChooser;
import javax.swing.JFrame;
import javax.swing.filechooser.FileFilter;
import javax.swing.filechooser.FileNameExtensionFilter;
import javax.vecmath.Point3f;
import javax.media.opengl.*;
import javax.swing.*;

import peasy.PeasyCam;

import controlP5.*;
import processing.opengl.*;


	private boolean dualExtrusionColoring = false ;

	PeasyCam cam;
	ControlP5 controlP5;
	PMatrix3D currCameraMatrix;
	PGraphicsOpenGL g3; 
        private boolean is2D = false;
	private String gCode;
	private ArrayList<LineSegment> objCommands; 
	private int curScale = 20;
        private int curLayer = 0;
        


	////////////ALPHA VALUES//////////////

	private final int TRANSPARENT = 20;
	private final int SOLID = 100;
	private final int SUPERSOLID = 255;

	//////////////////////////////////////

	////////////COLOR VALUES/////////////

	
	private final int RED = color(255,200,200);
	private final int BLUE = color(0, 255, 255);
	private final int PURPLE = color(242, 0, 255);
	private final int YELLOW = color(237, 255, 0);
	private final int OTHER_YELLOW = color(234, 212, 7);
	private final int GREEN = color(33, 255, 0);
	private final int WHITE = color(255, 255, 255);

	//////////////////////////////////////

	///////////SPEED VALUES///////////////

	private final int LOW_SPEED = 700;
	private final int MEDIUM_SPEED = 1400;
	private final int HIGH_SPEED = 1900;

	//////////////////////////////////////

	//////////SLIDER VALUES/////////////

	private int minSlider = 0;
	private int maxSlider;
	private int defaultValue;

	////////////////////////////////////

	/////////Canvas Size///////////////

	private int xSize = 800;
	private int ySize = 600;

	////////////////////////////////////
        private int camOffset = 70;


	public void setup() {
               //gCode = ("RectangularServoHorn2.gcode");
               //gCode = ("C:/Users/noah/Downloads/RoboArm/pig.gcode");
		//gCode = ("C:/Users/noah/Dropbox/Rep26Stuff/Example Files/Cupcake/Merged.gcode");
                size(xSize,ySize, OPENGL);
		frameRate(25);
                hint(ENABLE_NATIVE_FONTS);
		background(0);

		g3 = (PGraphicsOpenGL)g;
                hint(DISABLE_OPENGL_2X_SMOOTH);
                noSmooth();
                GL gl = g3.beginGL();  // always use the GL object returned by beginGL
               gl.glHint(gl.GL_CLIP_VOLUME_CLIPPING_HINT_EXT, gl.GL_FASTEST); //This line does not work with discrete graphcis
                gl.glEnable(GL.GL_CLIP_PLANE0);
                g3.endGL();
                
		cam = new PeasyCam(this, 0,  0, 0, camOffset); // parent, x, y, z, initial distance

		cam.setMinimumDistance(2);
		cam.setMaximumDistance(200);
		make3D();


		controlP5 = new ControlP5(this);
               CheckBox cb =  controlP5.addCheckBox("2DBox", xSize - 200, 38);
                cb.addItem("2D View",0);
              controlP5.setAutoDraw(false);
      		controlP5.addButton("Choose File...",10f,(xSize - 110),30,80,20);
		if(gCode != null)
                {
                generateObject();
                }
	}
	public void controlEvent(ControlEvent theEvent) 
        {
          if(theEvent.isGroup()) 
          {
           int checkChoice = (int)theEvent.group().arrayValue()[0];
        println("2D view is" + checkChoice);
            if(checkChoice == 1)
            {
            make2D();
            }
            if(checkChoice == 0)
            {
            make3D();
            }
          }
          else if(theEvent.controller().name() == "Choose File...")
          {
          selectFile();
          generateObject();
          }
	}
        public void make2D()
        {
          is2D = true;
          cam.reset();
          cam.setActive(false);
        }
        public void make3D()
        {
          is2D = false;
          cam.rotateX(-.37); //Make it obvious it is 3d to start
	  cam.rotateY(.1);
          cam.setActive(true);
        }
	public void generateObject()
	{
		GcodeViewParse gcvp = new GcodeViewParse();
		objCommands = (gcvp.toObj(readFiletoArrayList(gCode)));
		maxSlider = objCommands.get(objCommands.size() - 1).getLayer(); // Maximum slider value is highest layer
		defaultValue = maxSlider;
                controlP5.remove("Layer Slider");
		controlP5.addSlider("Layer Slider",minSlider,maxSlider,defaultValue,20,100,10,300).setNumberOfTickMarks(maxSlider);
		//controlP5.addControlWindow("ControlWindow", 50, 50, 20, 20);
		
                curLayer = (int)Math.round(controlP5.controller("Layer Slider").value());
	}
	public void draw() {

		lights();
		//ambientLight(128,128,128);
                background(0);
                 if(gCode != null)
                {
		hint(ENABLE_DEPTH_TEST);
		pushMatrix();
		noSmooth();

		float[] points = new float[6];
               
		int maxLayer = (int)Math.round(controlP5.controller("Layer Slider").value());
                
		int curTransparency = 0;
                beginShape(LINES);
		for(LineSegment ls : objCommands)
		{
			if(ls.getLayer() < maxLayer)
			{
				curTransparency = SOLID;
			}
			if(ls.getLayer() == maxLayer)
			{
				curTransparency = SUPERSOLID;
			}
			if(ls.getLayer() > maxLayer)
			{
				curTransparency = TRANSPARENT;
			}
			if(!ls.getExtruding())
			{
				stroke(WHITE,TRANSPARENT);
			}
			if(!dualExtrusionColoring)
			{
				if(ls.getExtruding())
				{
					if(ls.getSpeed() > LOW_SPEED && ls.getSpeed() < MEDIUM_SPEED)
					{
						stroke(PURPLE, curTransparency);
					}
					if(ls.getSpeed() > MEDIUM_SPEED && ls.getSpeed() < HIGH_SPEED)
					{
						stroke(BLUE, curTransparency);
					}
					else if(ls.getSpeed() >= HIGH_SPEED)
					{
						stroke(OTHER_YELLOW, curTransparency);
					}
					else //Very low speed....
					{
						stroke(GREEN, curTransparency);
					}
				}
			}
			if(dualExtrusionColoring)
			{
				if(ls.getExtruding())
				{
					if(ls.getToolhead() == 0)
					{
						stroke(BLUE, curTransparency);
					}
					if(ls.getToolhead() == 1)
					{
						stroke(GREEN, curTransparency);
					}
				}
			}
                      
                        if(!is2D || (ls.getLayer() == maxLayer))
                        {
			points = ls.getPoints();
                        
			//vertex(points[0],points[1],points[2],points[3], points[4], points[5]);
                          vertex(points[0],points[1],points[2]);
                          vertex(points[3],points[4],points[5]);
        		}
                    }
                    endShape();
                    if((curLayer != maxLayer) && is2D)
                    {
                      cam.setDistance(cam.getDistance() + (maxLayer - curLayer)*.3,0);
                    }
                     curLayer = maxLayer;
		popMatrix();
		// makes the gui stay on top of elements
		// drawn before.
                }
		hint(DISABLE_DEPTH_TEST);
		gui();
	}
	private void gui() {
		noSmooth();
		currCameraMatrix = new PMatrix3D(g3.camera);
		camera();
                
		controlP5.draw();
		g3.camera = currCameraMatrix;
	}
        void selectFile() {
          try
          {
            SwingUtilities.invokeAndWait(new Runnable() {
            public void run()
            {
                JFileChooser fc = new JFileChooser(".");
                
                fc.setDialogTitle("Choose a file...");
          
                int returned = fc.showOpenDialog(frame);
                if (returned == JFileChooser.APPROVE_OPTION) 
                {
                  File file = fc.getSelectedFile();
                  gCode = (String)file.getPath();
                  println(gCode);
                  
                }
            }
        });
          }
          catch(Exception e)
          {
            e.printStackTrace();
          }
        generateObject();
      }
	public void mouseMoved() {
		if(mouseX < 35 || (mouseY < 50 && mouseX > (xSize - 130)) || is2D)
		{
			cam.setActive(false);
		}
		else
		{
			cam.setActive(true);
		}
	}

	public ArrayList<String> readFiletoArrayList(String s) {
		ArrayList<String> vect;
		String lines[] = loadStrings(s);
                vect = new ArrayList<String>(Arrays.asList(lines));
		return vect;
	}

