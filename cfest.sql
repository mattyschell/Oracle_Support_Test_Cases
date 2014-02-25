--This is a test of topogeom constructor performance
--Submitted by CPB
--Contact: Matt Schell (matthew.c.schell@census.gov)

--sample call: sqlplus schel010@edevbnch @cfest.sql

--What happens: 
--1. Create a new topology
--2. Put a bunch of squares in it via add_polygon_geometry
--3. Add the squares to a topogeom via update constructors. Total of 10000 constructor calls


set serveroutput ON size 1000000;
BEGIN  --cleanup for possible rerun
SDO_TOPO.DELETE_TOPO_GEOMETRY_LAYER('CFEST','CFESTTAB','TOPOGEOM');
exception when others then
null;
end;
/
BEGIN
SDO_TOPO.DROP_TOPOLOGY('CFEST');
exception when others then
null;
end;
/
BEGIN
execute immediate 'DROP TABLE CFESTTAB';
exception when others then
null;
end; --end cleanup
/
BEGIN  --Create topology with 16 snapping digits
SDO_TOPO.create_topology('CFEST',.05,8265, NULL, NULL,NULL,NULL,16);
END;
/
BEGIN
--insert universal face
INSERT INTO CFEST_FACE$ VALUES (-1, null, sdo_list_type(), sdo_list_type(), null);
commit;
END;
/
BEGIN --create a dummy feature table
execute immediate 'create table CFESTTAB (id NUMBER, topogeom MDSYS.sdo_topo_geometry)';
FOR i IN 1 .. 100
LOOP
   --put 100 records into dummy feature table
   execute immediate 'insert into CFESTTAB VALUES(' || i || ',NULL) ';
end loop;
commit;
--add dummy table to topology
SDO_TOPO.add_topo_geometry_layer('CFEST','CFESTTAB','TOPOGEOM','POLYGON');
--initialize metadata per undocumented 11.2.0.2 rumors
SDO_TOPO.INITIALIZE_METADATA('CFEST');
end;
/
DECLARE
  res_number_array SDO_NUMBER_ARRAY;
  faces MDSYS.sdo_list_type := MDSYS.sdo_list_type();

BEGIN
   --put 100 square faces in the topology. Not bothering with explicit topomap for this test
   FOR i in 1 .. 100
   LOOP
   

      res_number_array := SDO_TOPO_MAP.ADD_POLYGON_GEOMETRY('CFEST',
        SDO_GEOMETRY(2003, 8265, NULL, SDO_ELEM_INFO_ARRAY(1,1003,1),
          SDO_ORDINATE_ARRAY( i/100,i/100, (i/100 + 0.5/100),i/100, (i/100 + 0.5/100),(i/100 + 0.5/100), i/100,(i/100 + 0.5/100), i/100,i/100)));

      faces.extend(1);
      faces(i) := res_number_array(1);

   END LOOP;
   
   dbms_output.put_line('Timestamp before constructors is ' || to_char(CURRENT_TIMESTAMP));


   for i in 1..faces.count loop  --for each of 100 faces
   
      FOR j IN 1 .. 100  --add each face to all 100 features
      LOOP

        update CFESTTAB a set a.topogeom = SDO_TOPO_GEOMETRY(
                  'CFEST', -- Topology name
                  3, -- Topology geometry type (polygon/multipolygon)
                  1, -- TG_LAYER_ID for this topology (from ALL_SDO_TOPO_METADATA)
                  SDO_TOPO_OBJECT_ARRAY (
                  SDO_TOPO_OBJECT (i, 3)),  --face id i
                  NULL) --no objects to delete
         WHERE a.id = j;
         
      END LOOP;
     
   end loop;
   
   commit;

   dbms_output.put_line('Timestamp after constructors is ' || to_char(CURRENT_TIMESTAMP));
   
END;
/
