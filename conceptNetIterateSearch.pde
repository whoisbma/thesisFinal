// max recursion number for each level
// search one object at a time, increment individual counter
// when reach limit, go one level down further

final int edgeLimit = 10;
final int levelLimit = 5;

final String path = "http://conceptnet5.media.mit.edu/data/5.2";

JSONObject json;

//int[] resultsTracker = new int[levelLimit];
//String[] resultsTrackerString = new String[levelLimit];
//String[] resultsTrackerRelString = new String[levelLimit];  // trying to record relation data to see if it semantically makes sense to me... breaking with a null pointer. 

//int offset = 0; 
int[] offsetArray = new int[levelLimit];
char[] offsetChar = new char[levelLimit]; //just to test
int whichToIncr = 0; // for testing above
boolean decrementing = false; 

String firstPath = "/c/en/person";
String nextPath = firstPath;

String[] prevPaths = new String[levelLimit]; 

boolean done = false;

void setup() {
  size(400, 400);
  background(250);
  frameRate(30);

  for (int i = 0; i < levelLimit; i++) {
    offsetArray[i] = 0;
    offsetChar[i] = 'O';
    prevPaths[i] = "";
  }
}

void draw() {
  if (done == false) {
    recurseDown(levelLimit-1);
  }
}

public void recurseDown(int currentLevel) {
  if (currentLevel < 0) {
    println("done");
    done = true; 
    return;
  }

  print("offset array: ");
  for (int i = 0; i < offsetArray.length; i++) {
    print(offsetArray[i]+ " - ");
  }
  println();

  print("which result: ");
  for (int i = 0; i < offsetChar.length; i++) {
    if (whichToIncr == i) {
      print("X - ");
    } else {
      print("O - ");
    }
  }
  println();
  print("search chain: " + firstPath + " --> ");
  for (int i = 0; i < whichToIncr; i++) {
    print(prevPaths[i] + " - ");
  }
  println();
  print("searching: " + nextPath + ", ");
  Edge newEdge = getEdgeOf(false, "", "", nextPath, offsetArray[whichToIncr], 1);
  if (newEdge == null) {
    println("found: NULL!!");
    println();

    //    offsetArray[currentLevel] = 0;
    //    if (whichToIncr > 0) {
    //      whichToIncr--;
    //      nextPath = prevPaths[whichToIncr];
    //    }
    //    decrementing = true;
    //    recurseDown(currentLevel - 1);
    //    

    offsetArray[currentLevel] = 0;
    if (whichToIncr > 0) {
      whichToIncr--;
      if (whichToIncr > 0) {
        nextPath = prevPaths[whichToIncr-1];
      } else {//else go to first starting path
        nextPath = firstPath;
      }
    }
    decrementing = true;
    recurseDown(currentLevel - 1);
  } else if (newEdge.omit == true) {    //should it be omitted?
    println("OMIT: " + newEdge.finalPath);
    println();
    offsetArray[currentLevel] = 0;
    if (whichToIncr > 0) {
      whichToIncr--;
      if (whichToIncr > 0) {
        nextPath = prevPaths[whichToIncr-1];
      } else {//else go to first starting path
        nextPath = firstPath;
      }
    }
    decrementing = true;
    recurseDown(currentLevel - 1);
  } else {
    //println("FINAL NAME: " + newEdge.finalName);
    println("found: " + newEdge.finalPath);
    prevPaths[whichToIncr] = newEdge.finalPath;

    if (newEdge.omit == true) {
      println("OMIT!!");
    }

    print("current chain: " + firstPath + " --> ");
    for (int i = 0; i < whichToIncr; i++) {
      print(prevPaths[i] + " - ");
    }
    print(newEdge.finalPath);
    println();
    println();

    if (whichToIncr < (levelLimit - 1) && decrementing == false) {
      whichToIncr++;  //increment level position to increment if its lower than level limit and not decrementing
      nextPath = newEdge.finalPath;    //update nextPath to go a level deeper
      return;
    }
    if (decrementing == true) {
      decrementing = false;
    }

    if (offsetArray[currentLevel] < (edgeLimit - 1)) { 
      offsetArray[currentLevel]++;  //increment offset at current level position
      //nextPath doesn't change, uses current one, just changes offset
    } else {
      offsetArray[currentLevel] = 0;
      if (whichToIncr > 0) {
        whichToIncr--;
        if (whichToIncr > 0) {
          nextPath = prevPaths[whichToIncr-1];
        } else {
          nextPath = firstPath;
        }
        //      } else {
        //        whichToIncr = 0;
        //        nextPath = prevPaths[0];
      }

      decrementing = true;
      recurseDown(currentLevel - 1);
    }
  }
}

public Edge getEdgeOf(boolean relTrue, String pathRel, String startOrEnd, String otherObject, int offsetNum, int level) { 
  try { 
    json = loadJSONObject(getPath(otherObject, relTrue, pathRel, startOrEnd, 1, offsetNum));
    //println("searching " + getPath(otherObject, relTrue, pathRel, startOrEnd, 1, offsetNum));
  } 
  catch (NullPointerException e) {
    e.printStackTrace();
    return null;
  } 

  //  if (json.hasKey("edges")) {
  //    println("has array of edges");
  //  } else {
  //    println("no array of edges!!");
  //  }
  JSONArray jsonEdges = json.getJSONArray("edges");
  JSONObject edge;
  String startLemmas, endLemmas, start, end, rel;
  String finalName = "";
  String finalPath = "";
  boolean omit = false;
  Edge thisEdge;

  if (jsonEdges.size() != 0) {
    //println("has array of edges");


    //for (int i = 0; i < theseEdges.length; i++) {
    edge = jsonEdges.getJSONObject(0);
    startLemmas = edge.getString("startLemmas");
    endLemmas = edge.getString("endLemmas");
    start = edge.getString("start");
    end = edge.getString("end");
    rel = edge.getString("rel"); 

    //get name and path
    if (end.equals(start)) {
      finalName = "REPEAT!";
      finalPath = "REPEAT!";
      omit = true;
    }  
    //this normally is an else if. but i'm getting bugs because i can't exclude the omits right now. so still giving them names and paths.
    /*else*/    if (end.contains(otherObject)) { 
      String splitString[] = split(start, "/");
      finalName = splitString[3];
      finalPath = start;
    } else if (start.contains(otherObject)) {
      String splitString[] = split(end, "/");
      finalName = splitString[3];
      finalPath = end;
    } else {
      finalName = "???";
      finalPath = "???";
    }

    //add an omit condition based on if it matches any path in the search chain?
    for (int i = 0; i < whichToIncr; i++) {
      if (prevPaths[i].equals(finalPath) || finalPath.equals(firstPath)) {
        omit = true;
      }
    }

    thisEdge = new Edge(startLemmas, endLemmas, start, end, rel, finalName, finalPath, level, omit);
    //    println("edge number " + i + ":" + "\n" +
    //        "\t" + "start = " + start + "\n" + 
    //        "\t" + "end = " + end + "\n" + 
    //        "\t" + "finalPath = " + finalPath + "\n" + 
    //        "\t" + "finalName = " + finalName + "\n" + 
    //        "\t" + "relation = " + rel + "\n" + 
    //        "\t" + "level = " + level);
    //}
    return thisEdge;
  } else {
    //println("no array of edges!!");
    return null;
  }
} 

public String getPath(String searchObject, boolean relTrue, String relString, String startOrEnd, int limitNum, int offsetNum) { 
  String newPath = "";
  // relation search, single query
  if (relTrue && offsetNum > 0) {//offsetTrue) {
    newPath = path + "/search?rel=" + relString + "&" + startOrEnd + "=" + searchObject + "&limit=" + limitNum + "&offset=" + offsetNum + "&filter=/c/en";
  } 
  //relation search, normal (limited) query
  if (relTrue && offsetNum == 0) {//!offsetTrue) { 
    newPath = path + "/search?rel=" + relString + "&" + startOrEnd + "=" + searchObject + "&limit=" + limitNum + "&filter=/c/en";
  } 
  // no relation search, normal (limited) query
  if (!relTrue && offsetNum == 0) {//!offsetTrue) {
    newPath = path + searchObject + "?limit=" + limitNum + "&filter=/c/en";
  }
  // no relation search, single query
  if (!relTrue && offsetNum > 0) {//offsetTrue) {
    newPath = path + searchObject + "?limit=" + limitNum + "&offset=" + offsetNum + "&filter=/c/en";
  } 
  //println("calculated path is " + newPath); 
  //println(newPath);
  return newPath;
} 

