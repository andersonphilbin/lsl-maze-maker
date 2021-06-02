string NOTECARD_NAME = "Maze Config"; // name of the card we are going to read
integer notecard_line = 0;
integer num_notecard_lines = 0;
key notecard_request = NULL_KEY;
list card_data; // the data in the card

integer genChnl = 2786;
integer wallChnl = 3056;
integer listenHandle;
vector prevPos;
rotation prevRot;
vector currPos;
rotation currRot;
vector zeroVec = <0.0, 0.0, 0.0>;
list cellPosList;
list xWallList;
list yWallList;
list primList;
integer primCount;

float xSpace = 1.0;
float ySpace = 1.0;
integer xCells = 4;
integer yCells = 4;
float wallThick = 1.0; // X or Y, depending on which wall list is being processed
float wallHeight = 6.0; //Z
float maxPrimLength = 10.0;
float xOffset = 0.0;
float yOffset = 0.0;
float zOffset = 0.0;
integer nGate = 0;
integer eGate = 0;
integer wGate = 0;
integer sGate = 0;

vector transform(vector origPos)
{
    return origPos - prevPos + currPos;
}

rez_prim_list(integer primStart)
{
    integer i;
    integer maxi = llGetListLength(primList) - 1;
    vector move;
    vector size;
    for (i = primStart; i <= maxi; i += 2) {
         llRezAtRoot("Maze wall", currPos, zeroVec, currRot, wallChnl + i);
         move = llList2Vector(primList, i + 1) - currPos;
         size = llList2Vector(primList, i);
         llRegionSay(wallChnl, llList2CSV(["Move", wallChnl + i, move.x, move.y, move.z]));
         //llSleep(0.5);
         llRegionSay(wallChnl, llList2CSV(["Size", wallChnl + i, size.x, size.y, size.z]));
         //llOwnerSay(llList2CSV(["Move", wallChnl + i, move.x, move.y, move.z]));
         //llOwnerSay(llList2CSV(["Size", wallChnl + i, size.x, size.y, size.z]));
         //llSleep(1.0);
    }
}


del_prim_list()
{
    integer i;
    integer maxi = llGetListLength(primList) - 1;
    vector move;
    vector size;
    for (i = 0; i <= maxi; i += 2) {
         llRegionSay(wallChnl, llList2CSV(["DeleteXXzy", wallChnl + i]));
         //llSleep(1.0);
    }
}

lock_prim_list()
{
    integer i;
    integer maxi = llGetListLength(primList) - 1;
    vector move;
    vector size;
    for (i = 0; i <= maxi; i += 2) {
         llRegionSay(wallChnl, llList2CSV(["LockXXzy", wallChnl + i]));
         //llSleep(1.0);
    }
}

integer check_card(string name) // check that that the named inventory item is a notecard
{
    integer i = llGetInventoryType(name);
    return i == INVENTORY_NOTECARD;
}

process_line(string cardLine)
{
    integer equalPos = llSubStringIndex(cardLine, "=");
    integer commentPos = llSubStringIndex(cardLine, "#");
    string name;
    string value;
    if (equalPos != 0 && (commentPos == 0 || commentPos > equalPos)) {
        name = llStringTrim(llGetSubString(cardLine, 0, equalPos - 1), STRING_TRIM);
        if (commentPos > 0) {
            value = llStringTrim(llGetSubString(cardLine, equalPos + 1, commentPos + 1), STRING_TRIM);
        } else {
            value = llStringTrim(llGetSubString(cardLine, equalPos + 1, -1), STRING_TRIM);
        }
    }
    if (name == "XSpace") {
        xSpace = (float)value;
    } else if (name == "YSpace") {
        ySpace = (float)value;
    } else if (name == "XCount") {
        xCells = (integer)value;
    } else if (name == "YCount") {
        yCells = (integer)value;
    } else if (name == "Thick") {
        wallThick = (float)value;
    } else if (name == "Height") {
        wallHeight = (float)value;
    } else if (name == "MaxLength") {
        maxPrimLength = (float)value;
    } else if (name == "XOffset") {
        xOffset = (float)value;
    } else if (name == "YOffset") {
        yOffset = (float)value;
    } else if (name == "ZOffset") {
        zOffset = (float)value;
    } else if (name == "NGate") {
        nGate = (integer)value;
    } else if (name == "EGate") {
        eGate = (integer)value;
    } else if (name == "WGate") {
        wGate = (integer)value;
    } else if (name == "SGate") {
        sGate = (integer)value;
    }
}

dump_notecard()
{
    llOwnerSay("the notecard contained the following data:");
    llOwnerSay(llDumpList2String(card_data, "\n"));
}

integer int_rand(integer bottom, integer top)
{
    integer randInt;
    if (bottom >= top) {
        randInt = bottom;
    } else {
        randInt = llFloor(llFrand((float)(top - bottom) + 1.0)) + bottom;
    }
    //llOwnerSay("int_rand: bottom " + (string)bottom + " top " + (string)top + " rand " + (string)randInt);
    return randInt;
}

integer calc_split(integer start, integer end)
{
    if ((end - start) > 1) {
        // Must generate an integer > start and < end
        return int_rand(start + 1, end - 1);
    } else {
        return start;
    }
}
// Maze is xCells x yCells
// xWallList contains (yCells - 1) elements, each containing xCells characters. Elements are numbered 0 to (yCells - 2).
// yWallList contains (xCells - 1) elements blah, blah, blah.
draw_wall_x(integer yPos, integer xStart, integer xEnd)
{
    integer ix;
    string wall = llList2String(xWallList, yPos - 1);
    string newWall = "";
    string newPart = "";
    for (ix = xStart; ix <= xEnd; ++ix) {
        newPart += "1";
    }
    //llOwnerSay("Before: " + wall);
    //llOwnerSay("Insert: " + newPart + " at: " + (string)yPos);
    if (xStart > 2) {
        newWall = llGetSubString(wall, 0, xStart - 2);
    }
    newWall += newPart;
    if (xEnd < xCells) {
        newWall += llGetSubString(wall, xEnd, -1);
    }
    //llOwnerSay("After: " + newWall);
    xWallList = llDeleteSubList(xWallList, yPos - 1, yPos - 1);
    xWallList = llListInsertList(xWallList, [newWall], yPos - 1);
}

draw_wall_y(integer xPos, integer yStart, integer yEnd)
{
    integer iy;
    string wall = llList2String(yWallList, xPos - 1);
    string newWall = "";
    string newPart = "";
    for (iy = yStart; iy <= yEnd; ++iy) {
        newPart += "1";
    }
    //llOwnerSay("Before: " + wall);
    //llOwnerSay("Insert: " + newPart + " at: " + (string)xPos);
    if (yStart > 2) {
        newWall = llGetSubString(wall, 0, yStart - 2);
    }
    newWall += newPart;
    if (yEnd < yCells) {
        newWall += llGetSubString(wall, yEnd, -1);
    }
    //llOwnerSay("After: " + newWall);
    yWallList = llDeleteSubList(yWallList, xPos - 1, xPos - 1);
    yWallList = llListInsertList(yWallList, [newWall], xPos - 1);
}

make_door_x(integer yPos, integer xStart, integer xEnd)
{
    integer ix = int_rand(xStart, xEnd);
    string wall = llList2String(xWallList, yPos - 1);
    string newWall = "";
    if (ix > 1) {
        newWall = llGetSubString(wall, 0, ix - 2);
    }
    newWall += "0";
    if (ix < xCells) {
        newWall += llGetSubString(wall, ix, -1);
    }
    //llOwnerSay("xDoor at: " + (string)ix + " before " + wall + " after " + newWall);
    xWallList = llDeleteSubList(xWallList, yPos - 1, yPos - 1);
    xWallList = llListInsertList(xWallList, [newWall], yPos - 1);
}

make_door_y(integer xPos, integer yStart, integer yEnd)
{
    integer iy = int_rand(yStart, yEnd);
    string wall = llList2String(yWallList, xPos - 1);
    string newWall = "";
    if (iy > 1) {
        newWall = llGetSubString(wall, 0, iy - 2);
    }
    newWall += "0";
    if (iy < yCells) {
        newWall += llGetSubString(wall, iy, -1);
    }
    //llOwnerSay("yDoor at: " + (string)iy + " before " + wall + " after " + newWall);
    yWallList = llDeleteSubList(yWallList, xPos - 1, xPos - 1);
    yWallList = llListInsertList(yWallList, [newWall], xPos - 1);
}

subdivide(integer xStart, integer yStart, integer xEnd, integer yEnd)
{
    //llOwnerSay("Start subdivide: xStart " + (string)xStart + " xEnd " + (string)xEnd);
    //llOwnerSay("Start subdivide: yStart " + (string)yStart + " yEnd " + (string)yEnd);
    // Four cases: 1 x 1, 1 x Y, X x 1, X x Y but only the last matters
    if ((xEnd - xStart) > 0 && (yEnd - yStart) > 0) {
        // Something to do
        integer xSplit = calc_split(xStart, xEnd);
        integer ySplit = calc_split(yStart, yEnd);
        //llOwnerSay("xStart " + (string)xStart + " xSplit " + (string)xSplit + " xEnd " + (string)xEnd);
        //llOwnerSay("yStart " + (string)yStart + " ySplit " + (string)ySplit + " yEnd " + (string)yEnd);
        draw_wall_x(ySplit, xStart, xEnd);
        draw_wall_y(xSplit, yStart, yEnd);
        integer doorWall = int_rand(1, 4);
        //llOwnerSay("doorWall at: " + (string)doorWall);
        // Walls for doors are NEWS = 1234, the doorWall doesn't get a door
        if (doorWall != 1) {
            make_door_y(xSplit, ySplit + 1, yEnd);
        }
        if (doorWall != 2) {
            make_door_x(ySplit, xSplit + 1, xEnd);
        }
        if (doorWall != 3) {
            make_door_x(ySplit, xStart, xSplit);
        }
        if (doorWall != 4) {
            make_door_y(xSplit, yStart, ySplit);
        }
        subdivide(xStart, yStart, xSplit, ySplit);
        subdivide(xSplit + 1, yStart, xEnd, ySplit);
        subdivide(xStart, ySplit + 1, xSplit, yEnd);
        subdivide(xSplit + 1, ySplit + 1, xEnd, yEnd);
    }
}

generate()
{
    llOwnerSay("Generator position: " + (string)currPos + " rotation: " + (string)currRot);
    string initWall = "";
    integer ix;
    integer iy;
    for (ix = 0; ix < xCells; ++ix) {initWall += "0";}
    xWallList = [];
    for (iy = 0; iy < (yCells - 1); ++iy) {xWallList += initWall;}
    initWall = "";
    for (iy = 0; iy < yCells; ++iy) {initWall += "0";}
    yWallList = [];
    for (ix = 0; ix < (xCells - 1); ++ix) {yWallList += initWall;}
    //llOwnerSay("xWall 1:" + llDumpList2String(xWallList, "\n"));
    //llOwnerSay("yWall 1:" + llDumpList2String(yWallList, "\n"));
    subdivide(1, 1, xCells, yCells);
    llOwnerSay("Wall map generation complete: " + (string) (llGetFreeMemory()) + " free memory");
    llOwnerSay("xWall\n" + llDumpList2String(xWallList, "\n"));
    llOwnerSay("yWall\n" + llDumpList2String(yWallList, "\n"));

    integer i;
    integer maxi = llGetListLength(xWallList) - 1;
    integer j;
    integer maxj;
    string wall;
    integer cellStart;
    integer cellEnd;
    integer extendStart = 0;
    integer extendEnd = 0;
    float startPos;
    float endPos;
    float remPrimLength;
    float primLength;
    for (i = 0; i <= maxi; i++) {
        wall = llList2String(xWallList, i);
        maxj = llStringLength(wall);
        cellStart = -1;
        cellEnd = -1;
        for (j = 0; j <= maxj; j++) {
            if (llGetSubString(wall, j, j) == "1") {
                if (cellStart == -1) {cellStart = j;}
            } else {
                if (cellStart != -1) {cellEnd = j - 1;}
            }
            if (cellEnd != -1) { //cellStart to cellEnd defines a wall segment
                //Need to determine intersections at start and end points (if none, then we extend the length)
                if (cellStart > 0) { //Extend the start if there is no Y wall adjacent (and it's not on the perimeter)
                    if ((llGetSubString(llList2String(yWallList, cellStart - 1), i, i) == "1") || (llGetSubString(llList2String(yWallList, cellStart - 1), i + 1, i + 1) == "1")) {
                        extendStart = 0;
                    } else {
                        extendStart = 1;
                    }
                }
                if (cellEnd < maxj - 1) {
                    if ((llGetSubString(llList2String(yWallList, cellEnd), i, i) == "1") || (llGetSubString(llList2String(yWallList, cellEnd), i + 1, i + 1) == "1")) {
                        extendEnd = 0;
                    } else {
                        extendEnd = 1;
                    }
                }
                startPos = (((float)cellStart - 0.5) * xSpace) - (((float)extendStart - 0.5) * wallThick);
                endPos = (((float)cellEnd + 0.5) * xSpace) + (((float)extendEnd - 0.5) * wallThick);
                primLength = endPos - startPos;
                remPrimLength = primLength;
                while (remPrimLength > maxPrimLength) {
                    primList += [<maxPrimLength, wallThick, wallHeight>];
                    primList += [transform(prevPos + <startPos + (maxPrimLength * 0.5), ((float)i + 0.5) * ySpace, 0.0>)];
                    remPrimLength -= maxPrimLength;
                    startPos += maxPrimLength;
                }
                primList += [<remPrimLength, wallThick, wallHeight>];
                primList += [transform(prevPos + <startPos + (remPrimLength * 0.5), ((float)i + 0.5) * ySpace, 0.0>)];
                //llOwnerSay("xWall segment for wall: " + (string)(i + 1) + " start " + (string)(cellStart + 1) + " end " + (string)(cellEnd + 1) + " s " + (string)extendStart + " e " + (string)extendEnd);
                cellStart = -1;
                cellEnd = -1;
                extendStart = 0;
                extendEnd = 0;
            }
        }
    }
    maxi = llGetListLength(yWallList) - 1;
    for (i = 0; i <= maxi; i++) {
        wall = llList2String(yWallList, i);
        maxj = llStringLength(wall);
        cellStart = -1;
        cellEnd = -1;
        for (j = 0; j <= maxj; j++) {
            if (llGetSubString(wall, j, j) == "1") {
                if (cellStart == -1) {cellStart = j;}
            } else {
                if (cellStart != -1) {cellEnd = j - 1;}
            }
            if (cellEnd != -1) { //cellStart to cellEnd defines a wall segment
                //We extend the length except at the perimeter and X T intersections
                if (cellStart > 0) {
                    if (llGetSubString(llList2String(xWallList, cellStart - 1), i, i + 1) == "11") {
                        extendStart = 0;
                    } else {
                        extendStart = 1;
                    }
                } else {
                    extendStart = 0;
                }
                if (cellEnd < maxj - 1) {
                    if (llGetSubString(llList2String(xWallList, cellEnd), i, i + 1) == "11") {
                        extendEnd = 0;
                    } else {
                        extendEnd = 1;
                    }
                } else {
                    extendEnd = 0;
                }
                startPos = (((float)cellStart - 0.5) * ySpace) - (((float)extendStart - 0.5) * wallThick);
                endPos = (((float)cellEnd + 0.5) * ySpace) + (((float)extendEnd - 0.5) * wallThick);
                primLength = endPos - startPos;
                remPrimLength = primLength;
                while (remPrimLength > maxPrimLength) {
                    primList += [<wallThick, maxPrimLength, wallHeight>];
                    primList += [transform(prevPos + <((float)i + 0.5) * xSpace, startPos + (maxPrimLength * 0.5), 0.0>)];
                    remPrimLength -= maxPrimLength;
                    startPos += maxPrimLength;
                }
                primList += [<wallThick, remPrimLength, wallHeight>];
                primList += [transform(prevPos + <((float)i + 0.5) * xSpace, startPos + (remPrimLength * 0.5), 0.0>)];
                //llOwnerSay("yWall segment for wall: " + (string)(i + 1) + " start " + (string)(cellStart + 1) + " end " + (string)(cellEnd + 1) + " s " + (string)extendStart + " e " + (string)extendEnd);
                cellStart = -1;
                cellEnd = -1;
                extendStart = 0;
                extendEnd = 0;
            }
        }
    }
    //llOwnerSay("primList\n" + llDumpList2String(primList, "\n"));
}

perimeter()
{
    llOwnerSay("Generator position: " + (string)currPos + " rotation: " + (string)currRot);
    // South wall
    float xStart;
    float yStart = currPos.y - (ySpace * 0.5);
    float xEnd = currPos.x + (((float)xCells - 0.5) * xSpace) + (wallThick * 0.5);
    float yEnd = yStart;
    float wallLen = (float)xCells * xSpace;
    float remPrimLength;
    //float primLength;

    if (sGate == 1) {
        wallLen -= (xSpace - wallThick);
    }
    xStart = xEnd - wallLen;
    remPrimLength = wallLen;
    while (remPrimLength > maxPrimLength) {
        primList += [<maxPrimLength, wallThick, wallHeight>];
        primList += [transform(prevPos + <xStart + (maxPrimLength * 0.5) - currPos.x, yStart - currPos.y, 0.0>)];
        remPrimLength -= maxPrimLength;
        xStart += maxPrimLength;
    }
    primList += [<remPrimLength, wallThick, wallHeight>];
    primList += [transform(prevPos + <xStart + (remPrimLength * 0.5) - currPos.x, yStart - currPos.y, 0.0>)];
    // North wall
    xStart = currPos.x - (0.5 * xSpace) - (wallThick * 0.5);
    yStart = currPos.y + (((float)yCells - 0.5) * ySpace);
    xEnd = currPos.x + (((float)xCells - 0.5) * xSpace) + (wallThick * 0.5);
    yEnd = yStart;
    wallLen = (float)xCells * xSpace;

    if (nGate == 1) {
        wallLen -= (xSpace - wallThick);
    }
    xEnd = xStart + wallLen;
    remPrimLength = wallLen;
    while (remPrimLength > maxPrimLength) {
        primList += [<maxPrimLength, wallThick, wallHeight>];
        primList += [transform(prevPos + <xStart + (maxPrimLength * 0.5) - currPos.x, yStart - currPos.y, 0.0>)];
        remPrimLength -= maxPrimLength;
        xStart += maxPrimLength;
    }
    primList += [<remPrimLength, wallThick, wallHeight>];
    primList += [transform(prevPos + <xStart + (remPrimLength * 0.5) - currPos.x, yStart - currPos.y, 0.0>)];
    // West wall
    xStart = currPos.x - (xSpace * 0.5);
    yStart = currPos.y - (0.5 * ySpace) - (wallThick * 0.5);
    xEnd = xStart;
    wallLen = (float)yCells * ySpace;

    if (wGate == 1) {
        wallLen -= (ySpace - wallThick);
    }
    yEnd = yStart + wallLen;
    remPrimLength = wallLen;
    while (remPrimLength > maxPrimLength) {
        primList += [<wallThick, maxPrimLength, wallHeight>];
        primList += [transform(prevPos + <xStart - currPos.x, yStart + (maxPrimLength * 0.5) - currPos.y, 0.0>)];
        remPrimLength -= maxPrimLength;
        yStart += maxPrimLength;
    }
    primList += [<wallThick, remPrimLength, wallHeight>];
    primList += [transform(prevPos + <xStart - currPos.x, yStart + (remPrimLength * 0.5) - currPos.y, 0.0>)];
    // East wall
    xStart = currPos.x + (((float)xCells - 0.5) * xSpace);
    yEnd = currPos.y + (((float)yCells - 0.5) * ySpace) + (wallThick * 0.5);
    xEnd = xStart;
    wallLen = (float)yCells * ySpace;

    if (eGate == 1) {
        wallLen -= (ySpace - wallThick);
    }
    yStart = yEnd - wallLen;
    remPrimLength = wallLen;
    while (remPrimLength > maxPrimLength) {
        primList += [<wallThick, maxPrimLength, wallHeight>];
        primList += [transform(prevPos + <xStart - currPos.x, yStart + (maxPrimLength * 0.5) - currPos.y, 0.0>)];
        remPrimLength -= maxPrimLength;
        yStart += maxPrimLength;
    }
    primList += [<wallThick, remPrimLength, wallHeight>];
    primList += [transform(prevPos + <xStart - currPos.x, yStart + (remPrimLength * 0.5) - currPos.y, 0.0>)];
}
 
default
{
    state_entry()
    {
        state init;
    }
}
 
state ready
{
    state_entry()
    {
        prevPos = <0.0, 0.0, 0.0>;
        prevRot = <0.0, 0.0, 0.0, 1.0>;
        currPos = llGetPos() + <xOffset, yOffset, zOffset>;
        currRot = llGetRot();
        primList = [];
        llSetText("Ready\nTouch to generate", <1, 1, 1>, 1.0);
    }
    touch_start(integer detected)
    {
        if (llGetOwner() == llDetectedKey(0)) {
            listenHandle = llListen(genChnl, "", llGetOwner(), "");
            llDialog(llDetectedKey(0), "Maze Generator\n\nPlease choose one of the below options.",
                     ["Reposition", "Generate", "Perimeter", "Delete", "Lock", "Instructions", "Dump data"], genChnl);
        } else {
             llGiveInventory( llDetectedKey(0), "Maze Brochure" );
        }
    }
    listen( integer channel, string name, key id, string message )
    {
        llListenRemove(listenHandle);
        if (message == "Dump data") {
            dump_notecard();
        } else if (message == "Generate") {
            primCount = llGetListLength(primList);
            generate();
            rez_prim_list(primCount);
        } else if (message == "Perimeter") {
            primCount = llGetListLength(primList);
            perimeter();
            rez_prim_list(primCount);
        } else if (message == "Delete") {
            del_prim_list();
            primList = [];
        } else if (message == "Lock") {
            lock_prim_list();
            primList = [];
        } else if (message == "Reposition") {
            prevPos = currPos;
            prevRot = currRot;
            currPos = llGetPos() + <xOffset, yOffset, zOffset>;
            currRot = llGetRot();
        } else if (message == "Instructions") {
            llGiveInventory( llDetectedKey(0), "Maze Instructions" );
        }
    }
    changed(integer change)
    {
        if (change & (CHANGED_INVENTORY)) // if someone edits the card, reset the script
        {
            llResetScript();
        }
    }
    state_exit()
    {
        llSetText("", <0, 0, 0>, 0);
    }
}
 
state init
{
    state_entry()
    {
        if (!check_card(NOTECARD_NAME)) // check the card exists
        {
            state error;
        }
        llSetText("initialising...", <1, 1, 1>, 0);
        notecard_request = NULL_KEY;
        notecard_line = 0;
        num_notecard_lines = 0;
        notecard_request = llGetNumberOfNotecardLines(NOTECARD_NAME); // ask for the number of lines in the card
        llSetTimerEvent(5.0); // if we don't hear back in 5 secs, then the card might have been empty
    }
    timer() // if we time out, it meant something went wrong - the notecard was probably empty
    {
        llSetTimerEvent(0.0);
        state error;
    }
    dataserver(key query_id, string data)
    {
        if (query_id == notecard_request) // make sure it's an answer to a question we asked - this should be an unnecessary check
        {
            llSetTimerEvent(0.0); // at least one line, so don't worry any more
            if (data == EOF) // end of the notecard, change to ready state
            {
                state ready;
            }
            else if (num_notecard_lines == 0) // first request is for the number of lines
            {
                num_notecard_lines = (integer)data;
                notecard_request = llGetNotecardLine(NOTECARD_NAME, notecard_line); // now get the first line
            }
            else
            {
                if (data != "" && llGetSubString(data, 0, 0) != "#") // ignore empty lines, or lines beginning with "#"
                {
                    card_data = (card_data = []) + card_data + data;
                    process_line(data);
                }
                ++notecard_line;
                notecard_request = llGetNotecardLine(NOTECARD_NAME, notecard_line); // ask for the next line
            }
        }
        // update the hover-text with the progress
        llSetText("read " + (string)(notecard_line) + " of " + (string)num_notecard_lines + " lines", <1, 1, 1>, 1.0);
    }
 
    state_exit()
    {
        llSetText("", <0, 0, 0>, 0);
    }
}
 
state error
{
    state_entry()
    {
        llOwnerSay("something went wrong; try checking that the notecard [ " + NOTECARD_NAME + " ] exists and contains data");
    }
    changed(integer change)
    {
        if (change & CHANGED_INVENTORY)
        {
            llResetScript();
        }
    }
}
