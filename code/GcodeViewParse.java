import java.util.List;
import java.util.ArrayList;
import java.util.Arrays;

import javax.vecmath.Point3f;


public class GcodeViewParse {
	private static boolean debugVals = false;

	public GcodeViewParse()
	{

	}
	public ArrayList<LineSegment> toObj(ArrayList<String> gcode)
	{
		float speed = 2; //DEFAULTS to 2
		Point3f lastPoint = null;
		Point3f curPoint = null;
		int curLayer = 0;
		int curToolhead = 0;
		float parsedX, parsedY, parsedZ, parsedF;
		float tolerance = .0002f;
		ArrayList<LineSegment> lines = new ArrayList<LineSegment>();
		float[] lastCoord = { 0.0f, 0.0f, 0.0f};
		boolean currentExtruding = false;
		for(String s : gcode)
		{
			if(s.matches(".*M101.*"))
			{
				currentExtruding = true;
			}
			if(s.matches(".*M103.*"))
			{
				currentExtruding = false;
			}
			if(s.matches(".*T0.*"))
			{
				curToolhead = 0;
			}
			if(s.matches(".*T1.*"))
			{
				curToolhead = 1;
			}
			if (s.matches(".*G1.*")) 
			{
				String[] sarr = s.split(" ");
				parsedX = parseCoord(sarr, 'X');
				parsedY = parseCoord(sarr, 'Y');
				parsedZ = parseCoord(sarr, 'Z');
				parsedF = parseCoord(sarr, 'F');

				//System.out.println(Arrays.toString(sarr));
				if(!Float.isNaN(parsedX))
				{
					lastCoord[0] = parsedX;
				}
				if(!Float.isNaN(parsedY))
				{
					lastCoord[1] = parsedY;
				}
				if(!Float.isNaN(parsedZ))
				{
					if (!(Math.abs(parsedZ - lastCoord[2]) <= tolerance))
					{
						curLayer++;
					}
					lastCoord[2] = parsedZ;
				}
				if(!Float.isNaN(parsedF))
				{
					speed = parsedF;
				}
				if(!(Float.isNaN(lastCoord [0]) || Float.isNaN(lastCoord [1]) || Float.isNaN(lastCoord [2])))
				{
					if(debugVals)
					{
						System.out.println(lastCoord[0] + "," + lastCoord [1] + "," + lastCoord[2] + ", speed =" + speed + 
								", layer=" + curLayer);
					}
					curPoint = new Point3f(lastCoord[0], lastCoord[1], lastCoord[2]);

					if(lastPoint != null)
					{

						lines.add(new LineSegment(lastPoint, curPoint, curLayer, speed, curToolhead, currentExtruding));
					}
					lastPoint = curPoint;
				}
			}

		}
		return lines;

	}


	private float parseCoord(String[] sarr, char c)
	{
		for(String t : sarr)
		{
			if(t.matches("\\s*[" + c + "]\\s*-*[\\d|\\.]+"))
			{
				//System.out.println("te : " + t);
				return Float.parseFloat(t.substring(1,t.length()));
			}
		}
		return Float.NaN;
	}
}
