CLASS zcl_kf_ec_status_crit DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES if_sadl_exit_calc_element_read.

ENDCLASS.


CLASS zcl_kf_ec_status_crit IMPLEMENTATION.

  METHOD if_sadl_exit_calc_element_read~get_calculation_info.

    IF line_exists(
         it_requested_calc_elements[
           table_line = 'STATUS_CRITICALITY'
         ]
       ).

      INSERT CONV string( 'STATUS' )
        INTO TABLE et_requested_orig_elements.

    ENDIF.

  ENDMETHOD.


  METHOD if_sadl_exit_calc_element_read~calculate.

    DATA lt_original_data
      TYPE STANDARD TABLE OF zc_kf_ec_claim
      WITH DEFAULT KEY.

    DATA lt_calculated_data
      TYPE STANDARD TABLE OF zc_kf_ec_claim
      WITH DEFAULT KEY.

    lt_original_data =
      CORRESPONDING #( it_original_data ).

    LOOP AT lt_original_data INTO DATA(ls_original).

      DATA(ls_calculated) =
        VALUE zc_kf_ec_claim( ).

      ls_calculated-status_criticality =
        SWITCH #(
          ls_original-status
          WHEN 'Open'      THEN 0
          WHEN 'Submitted' THEN 2
          WHEN 'Approved'  THEN 3
          WHEN 'Rejected'  THEN 1
          WHEN 'Paid'      THEN 5
          ELSE                  0
        ).

      APPEND ls_calculated
        TO lt_calculated_data.

    ENDLOOP.

    ct_calculated_data =
      CORRESPONDING #( lt_calculated_data ).

  ENDMETHOD.

ENDCLASS.
