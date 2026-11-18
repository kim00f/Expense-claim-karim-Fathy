CLASS zcl_kf_ec_nr_setup DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

ENDCLASS.



CLASS ZCL_KF_EC_NR_SETUP IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

DATA lt_interval TYPE cl_numberrange_intervals=>nr_interval.
lt_interval = VALUE #(
(
nrrangenr = '01'
fromnumber = '0000000001'
tonumber = '9999999999'
)
).
TRY.
cl_numberrange_intervals=>create(
EXPORTING
object = 'ZKF_EC_NR'
interval = lt_interval
IMPORTING
error = DATA(lv_error)
error_inf = DATA(ls_error_info)
error_iv = DATA(lt_error_intervals)
warning = DATA(lv_warning)
).
out->write( 'Interval 01 created successfully.' ).
CATCH cx_nr_object_not_found INTO DATA(lx_object).
out->write( lx_object->get_text( ) ).
CATCH cx_number_ranges INTO DATA(lx_range).
out->write( lx_range->get_text( ) ).
ENDTRY.  ENDMETHOD.
ENDCLASS.
