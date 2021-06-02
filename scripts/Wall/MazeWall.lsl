integer channel = 3056;
integer listen_handle;
integer start_param;
list command;
integer comm_len;

delete_prim()
{
    llDie();
}
move_prim(vector offset)
{
    vector newPos = llGetPos() + offset;
    do {
        llSetPos(newPos);
    }
    while (llVecDist(newPos, llGetPos()) > 0.01);
}
size_prim(vector newsize)
{
    llSetScale(newsize);
}
lock_prim()
{
    llRemoveInventory(llGetScriptName());
}
 
default
{
    state_entry()
    {   // Registers the listen to the owner of the object at the moment of the call.
        // This does not automatically update when the owner changes.
        // Change 0 to another positive number to listen for '/5 hello' style of chat.
        start_param = llGetStartParameter( );
        //llOwnerSay((string)llGetKey() + " entry param " + (string)start_param);
        listen_handle = llListen(channel, "", (key)"", "");
    }
    listen( integer chnl, string name, key id, string message )
    {
        //Commands:
        //"DeleteXXzy,start_param" Delete the prim
        //"Move,start_param,posX,posY,posZ" Move the prim by the specified distances
        //"Size,start_param,sizeX,sizeY,sizeZ" Set the size of the prim
        //"LockXXzy,start_param" Delete this script thus locking the prim
        //llOwnerSay((string)llGetKey() + " Param " + (string)start_param + " " + message);
        command = llCSV2List(message);
        comm_len = llGetListLength(command);
        if (comm_len > 1 && llList2Integer(command, 1) == start_param) {
            if(llList2String(command, 0) == "DeleteXXzy") {
                delete_prim();
            } else if (llList2String(command, 0) == "LockXXzy") {
                lock_prim();
            } else if (comm_len > 3) {
                if (llList2String(command, 0) == "Move") {
                    move_prim(<llList2Float(command, 2), llList2Float(command, 3), llList2Float(command, 4)>);
                } else if (llList2String(command, 0) == "Size") {
                    size_prim(<llList2Float(command, 2), llList2Float(command, 3), llList2Float(command, 4)>);
                }
            }
        }
        
        // Stop listening until script is reset
        //llListenRemove(listen_handle);
    }
    on_rez(integer param)
    {   // Triggered when the object is rezed, like after the object had been sold from a vendor
        //llResetScript();//By resetting the script on rez it forces the listen to re-register.
        start_param = param;
        //llOwnerSay((string)llGetKey() + " on_rez param " + (string)start_param);
    }
    changed(integer mask)
    {   // Triggered when the object containing this script changes owner.
        if(mask & CHANGED_OWNER)
        {
            llResetScript();
        }
    }
}
