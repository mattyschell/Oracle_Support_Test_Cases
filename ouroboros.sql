--This is a new flavor of the "Get_Geometry or Get_Topo_Elements CONNECT BY loop" bug
--unlike SR 3-2061292261 opened in August 2010 this loop occurs in the topo hierarchy rather than at level 1
--Submitted by CPB
--Contact: Matt Schell (matthew.c.schell@census.gov)

--Success will look like: nothing, script completes without error
--failure will look like: error
--                             ORA-01436: CONNECT BY loop in user data
--                             ORA-06512: at "MDSYS.SDO_TOPO_GEOMETRY", line 1289


--If script is being rerun, start with layer cleanups. Reverse order for layers higher in the hierarchy
BEGIN
SDO_TOPO.DELETE_TOPO_GEOMETRY_LAYER('OUROBOROS','OUROBOROS10','TOPOGEOM');
SDO_TOPO.DELETE_TOPO_GEOMETRY_LAYER('OUROBOROS','OUROBOROS9','TOPOGEOM');
SDO_TOPO.DELETE_TOPO_GEOMETRY_LAYER('OUROBOROS','OUROBOROS8','TOPOGEOM');
SDO_TOPO.DELETE_TOPO_GEOMETRY_LAYER('OUROBOROS','OUROBOROS1','TOPOGEOM');
SDO_TOPO.DELETE_TOPO_GEOMETRY_LAYER('OUROBOROS','OUROBOROS2','TOPOGEOM');
SDO_TOPO.DELETE_TOPO_GEOMETRY_LAYER('OUROBOROS','OUROBOROS3','TOPOGEOM');
SDO_TOPO.DELETE_TOPO_GEOMETRY_LAYER('OUROBOROS','OUROBOROS4','TOPOGEOM');
SDO_TOPO.DELETE_TOPO_GEOMETRY_LAYER('OUROBOROS','OUROBOROS5','TOPOGEOM');
SDO_TOPO.DELETE_TOPO_GEOMETRY_LAYER('OUROBOROS','OUROBOROS6','TOPOGEOM');
SDO_TOPO.DELETE_TOPO_GEOMETRY_LAYER('OUROBOROS','OUROBOROS7','TOPOGEOM');
exception when others then
null;
end;
/
--rerun drop topology
BEGIN
SDO_TOPO.DROP_TOPOLOGY('OUROBOROS');
exception when others then
null;
end;
/
--rerun drop the tables
BEGIN
execute immediate 'DROP TABLE OUROBOROS1';
execute immediate 'DROP TABLE OUROBOROS2';
execute immediate 'DROP TABLE OUROBOROS3';
execute immediate 'DROP TABLE OUROBOROS4';
execute immediate 'DROP TABLE OUROBOROS5';
execute immediate 'DROP TABLE OUROBOROS6';
execute immediate 'DROP TABLE OUROBOROS7';
execute immediate 'DROP TABLE OUROBOROS8';
execute immediate 'DROP TABLE OUROBOROS9';
execute immediate 'DROP TABLE OUROBOROS10';
exception when others then
null;
end;
/

------------
--START
------------

--Create topology
EXEC SDO_TOPO.create_topology('OUROBOROS',.05,8265, NULL, NULL,NULL,NULL,16);

--insert universal face
INSERT INTO OUROBOROS_FACE$ VALUES (-1, null, sdo_list_type(), sdo_list_type(), null);
commit;

--create 10 dummy tables.  Not all are really necessary, 10 for fun
create table OUROBOROS1 (id NUMBER, topogeom MDSYS.sdo_topo_geometry);
create table OUROBOROS2 (id NUMBER, topogeom MDSYS.sdo_topo_geometry);
create table OUROBOROS3 (id NUMBER, topogeom MDSYS.sdo_topo_geometry);
create table OUROBOROS4 (id NUMBER, topogeom MDSYS.sdo_topo_geometry);
create table OUROBOROS5 (id NUMBER, topogeom MDSYS.sdo_topo_geometry);
create table OUROBOROS6 (id NUMBER, topogeom MDSYS.sdo_topo_geometry);
create table OUROBOROS7 (id NUMBER, topogeom MDSYS.sdo_topo_geometry);
create table OUROBOROS8 (id NUMBER, topogeom MDSYS.sdo_topo_geometry);
create table OUROBOROS9 (id NUMBER, topogeom MDSYS.sdo_topo_geometry);
create table OUROBOROS10 (id NUMBER, topogeom MDSYS.sdo_topo_geometry);

--add dummy tables to topology
exec SDO_TOPO.add_topo_geometry_layer('OUROBOROS','OUROBOROS1','TOPOGEOM','POLYGON');
exec SDO_TOPO.add_topo_geometry_layer('OUROBOROS','OUROBOROS2','TOPOGEOM','POLYGON');
exec SDO_TOPO.add_topo_geometry_layer('OUROBOROS','OUROBOROS3','TOPOGEOM','POLYGON');
exec SDO_TOPO.add_topo_geometry_layer('OUROBOROS','OUROBOROS4','TOPOGEOM','POLYGON');
exec SDO_TOPO.add_topo_geometry_layer('OUROBOROS','OUROBOROS5','TOPOGEOM','POLYGON');
exec SDO_TOPO.add_topo_geometry_layer('OUROBOROS','OUROBOROS6','TOPOGEOM','POLYGON');
exec SDO_TOPO.add_topo_geometry_layer('OUROBOROS','OUROBOROS7','TOPOGEOM','POLYGON');
exec SDO_TOPO.add_topo_geometry_layer('OUROBOROS','OUROBOROS8','TOPOGEOM','POLYGON');
--make layer 9 a parent of layer 8
exec SDO_TOPO.add_topo_geometry_layer('OUROBOROS','OUROBOROS9','TOPOGEOM','POLYGON', NULL, 8);
--make layer 10 a parent of layer 9
exec SDO_TOPO.add_topo_geometry_layer('OUROBOROS','OUROBOROS10','TOPOGEOM','POLYGON', NULL, 9);

--load a topomap
exec SDO_TOPO_MAP.CREATE_TOPO_MAP('OUROBOROS','OUROBOROS_MAP');
exec SDO_TOPO_MAP.LOAD_TOPO_MAP('OUROBOROS_MAP', 'TRUE','TRUE');

--insert a 4x4 grid of edges, 16 faces. No real reason for this number either 
declare
liney  mdsys.sdo_geometry;
edge_idz  mdsys.sdo_number_array := mdsys.sdo_number_array();
begin
   for i in 1 .. 5
   loop
 
      for j in 1 .. 5
      loop
      
         liney := SDO_GEOMETRY(2002, 8265, NULL, SDO_ELEM_INFO_ARRAY(1,2,1),
                               SDO_ORDINATE_ARRAY(j,i, j+1,i));
                               
         edge_idz := SDO_TOPO_MAP.ADD_LINEAR_GEOMETRY(NULL, liney);
         
         liney := SDO_GEOMETRY(2002, 8265, NULL, SDO_ELEM_INFO_ARRAY(1,2,1),
                               SDO_ORDINATE_ARRAY(j,i, j,i+1));
                               
         edge_idz := SDO_TOPO_MAP.ADD_LINEAR_GEOMETRY(NULL, liney);
         
      end loop;  
   
   end loop;
end;
/

--commit and initialize
exec SDO_TOPO_MAP.COMMIT_TOPO_MAP();
exec SDO_TOPO_MAP.DROP_TOPO_MAP('OUROBOROS_MAP');
exec SDO_TOPO.INITIALIZE_METADATA('OUROBOROS');

--add all the faces to layer 8
begin
   for i in 1 .. 16
   loop
      execute immediate 'insert into ouroboros8 values(:p1,:p2)' 
         using i, sdo_topo_geometry('OUROBOROS',3,8,SDO_TOPO_OBJECT_ARRAY(SDO_TOPO_OBJECT(i,3))); 
   
   end loop;
end;
/   

--build layer 9 on some bits of layer 8 
--the third tg_id relation$ record of layer 9 will look like this
--  tg_layer_id tg_id topo_id topo_type
--  9           3     8       12
--in order to hit this relation$ record in 8
--  tg_layer_id tg_id topo_id topo_type
--  8           12    9       3

--this one makes tg_id 1, put it on tg_id 5 of the child, doesnt really matter
insert into ouroboros9 values(1, SDO_TOPO_GEOMETRY('OUROBOROS',3,9, SDO_TGL_OBJECT_ARRAY(SDO_TGL_OBJECT(8,5))));
--tg_id 2, put it on 6 of the child, no reason
insert into ouroboros9 values(2, SDO_TOPO_GEOMETRY('OUROBOROS',3,9, SDO_TGL_OBJECT_ARRAY(SDO_TGL_OBJECT(8,6))));
--tg_id 3, the target connect by.  Built on tg_id 12 
insert into ouroboros9 values(3, SDO_TOPO_GEOMETRY('OUROBOROS',3,9, SDO_TGL_OBJECT_ARRAY(SDO_TGL_OBJECT(8,12))));
commit;

--build layer 10 on the baddie in layer 9, tg_id 3
--  tg_layer_id tg_id topo_id topo_type
--  9           3     8       12             (<--this is the child in 9)
insert into ouroboros10 values(1, SDO_TOPO_GEOMETRY('OUROBOROS',3,10, SDO_TGL_OBJECT_ARRAY(SDO_TGL_OBJECT(9,3))));
commit;

--topo validates
DECLARE
res_varchar varchar2(4000);
BEGIN
res_varchar := SDO_TOPO_MAP.VALIDATE_TOPOLOGY('OUROBOROS');
END;
/

--
--
--TEST 1: Throws error 
--
--
select a.topogeom.get_topo_elements() from ouroboros10 a;
--ORA-01436: CONNECT BY loop in user data
--ORA-06512: at "MDSYS.SDO_TOPO_GEOMETRY", line 1289

--
--
--TEST 1 repeat with get_geometry. Line numbers of the error are different
--
--
select a.topogeom.get_geometry() from ouroboros10 a;
--ORA-01436: CONNECT BY loop in user data
--ORA-06512: at "MDSYS.SDO_TOPO_GEOMETRY", line 1059

exit;


