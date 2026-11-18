CLASS lhc_zr_kf_ec_receipt DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS updateReceiptCount FOR DETERMINE ON MODIFY
      keys FOR ZR_KF_EC_RECEIPT~updateReceiptCount.
    METHODS validateReceiptFile FOR VALIDATE ON SAVE
      keys FOR ZR_KF_EC_RECEIPT~validateReceiptFile.

ENDCLASS.

CLASS lhc_zr_kf_ec_receipt IMPLEMENTATION.

  METHOD updateReceiptCount.

  READ ENTITIES OF zr_kf_ec_claim IN LOCAL MODE
    ENTITY zr_kf_ec_receipt BY \_line
      FROM CORRESPONDING #( keys )
    LINK DATA(lt_link).

  CHECK lt_link IS NOT INITIAL.

  DATA(ls_line) = lt_link[ 1 ]-target.

  READ ENTITIES OF zr_kf_ec_claim IN LOCAL MODE
    ENTITY zr_kf_ec_line BY \_RECEIPT
      FIELDS ( receipt_uuid )
      WITH VALUE #(
        ( %tky = ls_line-%tky )
      )
    RESULT DATA(lt_receipts).

  MODIFY ENTITIES OF zr_kf_ec_claim IN LOCAL MODE
    ENTITY zr_kf_ec_line
      UPDATE FIELDS ( number_of_receipts )
      WITH VALUE #(
        (
          %tky               = ls_line-%tky
          number_of_receipts = lines( lt_receipts )
        )
      ).

ENDMETHOD.

  METHOD validateReceiptFile.

  CONSTANTS lc_max_file_size TYPE i VALUE 2097152.

  READ ENTITIES OF zr_kf_ec_claim IN LOCAL MODE
    ENTITY zr_kf_ec_receipt
    FIELDS (
      receipt_file
      filename
      mimetype
    )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_receipts).

  LOOP AT lt_receipts INTO DATA(ls_receipt).

    IF ls_receipt-receipt_file IS INITIAL.
      CONTINUE.
    ENDIF.


    IF to_lower( ls_receipt-mimetype ) <> 'application/pdf'.

      APPEND VALUE #(
        %tky = ls_receipt-%tky
      ) TO failed-zr_kf_ec_receipt.

      DATA(lv_type_message) =
        |Receipt { ls_receipt-filename } is not a PDF file. Only PDF receipts are accepted.|.

      APPEND VALUE #(
        %tky = ls_receipt-%tky

        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = lv_type_message
        )

        %element-receipt_file = if_abap_behv=>mk-on

      ) TO reported-zr_kf_ec_receipt.

    ENDIF.


    DATA(lv_file_size) = xstrlen( ls_receipt-receipt_file ).

    IF lv_file_size > lc_max_file_size.

      APPEND VALUE #(
        %tky = ls_receipt-%tky
      ) TO failed-zr_kf_ec_receipt.

      DATA(lv_size_message) =
        |Receipt { ls_receipt-filename } is larger than 2 MB.|.

      APPEND VALUE #(
        %tky = ls_receipt-%tky

        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = lv_size_message
        )

        %element-receipt_file = if_abap_behv=>mk-on

      ) TO reported-zr_kf_ec_receipt.

    ENDIF.

  ENDLOOP.

ENDMETHOD.

ENDCLASS.





CLASS lhc_zr_kf_ec_line DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS setLineNumber FOR DETERMINE ON MODIFY
      keys FOR ZR_KF_EC_LINE~setLineNumber.
    METHODS calculateTotal FOR DETERMINE ON MODIFY
      keys FOR ZR_KF_EC_LINE~calculateTotal.
    METHODS setReceiptRequired FOR DETERMINE ON MODIFY
      keys FOR ZR_KF_EC_LINE~setReceiptRequired.
    METHODS setLineCurrency FOR DETERMINE ON MODIFY
      keys FOR ZR_KF_EC_LINE~setLineCurrency.
    METHODS validateAmount FOR VALIDATE ON SAVE
      keys FOR ZR_KF_EC_LINE~validateAmount.
    METHODS validateExpenseDate FOR VALIDATE ON SAVE
      keys FOR ZR_KF_EC_LINE~validateExpenseDate.
    METHODS validateCategory FOR VALIDATE ON SAVE
      keys FOR ZR_KF_EC_LINE~validateCategory.
    METHODS validateRequiredReceipt FOR VALIDATE ON SAVE
      keys FOR ZR_KF_EC_LINE~validateRequiredReceipt.
    METHODS validateMealsLimit FOR VALIDATE ON SAVE
      keys FOR ZR_KF_EC_LINE~validateMealsLimit.
    METHODS validateHotelPerDay FOR VALIDATE ON SAVE
      keys FOR ZR_KF_EC_LINE~validateHotelPerDay.


ENDCLASS.

CLASS lhc_zr_kf_ec_line IMPLEMENTATION.

METHOD setLineNumber.

  READ ENTITIES OF zr_kf_ec_claim IN LOCAL MODE
    ENTITY zr_kf_ec_line BY \_claim
      FROM CORRESPONDING #( keys )
    LINK DATA(lt_links).

  CHECK lt_links IS NOT INITIAL.

  LOOP AT lt_links INTO DATA(ls_link).

    DATA(ls_line_key)  = ls_link-source.
    DATA(ls_claim_key) = ls_link-target.

    READ ENTITIES OF zr_kf_ec_claim IN LOCAL MODE
      ENTITY zr_kf_ec_claim BY \_line
      FIELDS ( line_number )
      WITH VALUE #(
        ( %tky = ls_claim_key-%tky )
      )
      RESULT DATA(lt_lines).

    DATA(lv_max_line) = 0.

    LOOP AT lt_lines INTO DATA(ls_line).

      IF ls_line-line_number IS INITIAL.
        CONTINUE.
      ENDIF.

      DATA(lv_line_number) =
        CONV i( ls_line-line_number ).

      IF lv_line_number > lv_max_line.
        lv_max_line = lv_line_number.
      ENDIF.

    ENDLOOP.

    DATA(lv_next_line) = lv_max_line + 10.

    MODIFY ENTITIES OF zr_kf_ec_claim IN LOCAL MODE
      ENTITY zr_kf_ec_line
      UPDATE FIELDS ( line_number )
      WITH VALUE #(
        (
          %tky        = ls_line_key-%tky
          line_number = lv_next_line
        )
      ).

  ENDLOOP.

ENDMETHOD.

METHOD calculateTotal.

  READ ENTITIES OF zr_kf_ec_claim IN LOCAL MODE
    ENTITY zr_kf_ec_line BY \_claim
      FROM CORRESPONDING #( keys )
    LINK DATA(lt_link).

  CHECK lt_link IS NOT INITIAL.

  DATA(ls_claim) = lt_link[ 1 ]-target.

  READ ENTITIES OF zr_kf_ec_claim IN LOCAL MODE
    ENTITY zr_kf_ec_claim BY \_line
      FIELDS ( amount )
      WITH VALUE #(
        ( %tky = ls_claim-%tky )
      )
    RESULT DATA(lt_lines).

  DATA lv_total TYPE zkf_ec_claim-total_amount.

  LOOP AT lt_lines INTO DATA(ls_line).
    lv_total = lv_total + ls_line-amount.
  ENDLOOP.

  MODIFY ENTITIES OF zr_kf_ec_claim IN LOCAL MODE
    ENTITY zr_kf_ec_claim
      UPDATE FIELDS ( total_amount )
      WITH VALUE #(
        (
          %tky         = ls_claim-%tky
          total_amount = lv_total
        )
      ).

ENDMETHOD.

  METHOD setReceiptRequired.

  READ ENTITIES OF zr_kf_ec_claim IN LOCAL MODE
    ENTITY zr_kf_ec_line
    FIELDS ( amount )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_lines).

  MODIFY ENTITIES OF zr_kf_ec_claim IN LOCAL MODE
    ENTITY zr_kf_ec_line
    UPDATE FIELDS ( receipt_required )
    WITH VALUE #(
      FOR ls_line IN lt_lines
      (
        %tky = ls_line-%tky

        receipt_required = COND #(
          WHEN ls_line-amount > 50
          THEN abap_true
          ELSE abap_false
        )
      )
    ).

ENDMETHOD.

 METHOD setLineCurrency.

  READ ENTITIES OF zr_kf_ec_claim IN LOCAL MODE
    ENTITY zr_kf_ec_line BY \_claim
      FROM CORRESPONDING #( keys )
    LINK DATA(lt_link).

  LOOP AT lt_link INTO DATA(ls_link).

    DATA(ls_claim) = ls_link-target.
    DATA(ls_line)  = ls_link-source.

    READ ENTITIES OF zr_kf_ec_claim IN LOCAL MODE
      ENTITY zr_kf_ec_claim
      FIELDS ( currency_code )
      WITH VALUE #(
        ( %tky = ls_claim-%tky )
      )
      RESULT DATA(lt_claims).

    CHECK lt_claims IS NOT INITIAL.

    MODIFY ENTITIES OF zr_kf_ec_claim IN LOCAL MODE
      ENTITY zr_kf_ec_line
      UPDATE FIELDS ( currency_code )
      WITH VALUE #(
        (
          %tky          = ls_line-%tky
          currency_code = lt_claims[ 1 ]-currency_code
        )
      ).

  ENDLOOP.

ENDMETHOD.




  METHOD validateAmount.

  READ ENTITIES OF zr_kf_ec_claim IN LOCAL MODE
    ENTITY zr_kf_ec_line
    FIELDS ( line_number amount )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_lines).

  LOOP AT lt_lines INTO DATA(ls_line).

    IF ls_line-amount <= 0.

      APPEND VALUE #(
        %tky = ls_line-%tky
      ) TO failed-zr_kf_ec_line.

      DATA(lv_message) =
        |Line { ls_line-line_number }: amount must be greater than zero.|.

      APPEND VALUE #(
        %tky = ls_line-%tky

        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = lv_message
        )

        %element-amount = if_abap_behv=>mk-on

      ) TO reported-zr_kf_ec_line.

    ENDIF.

  ENDLOOP.

ENDMETHOD.

  METHOD validateExpenseDate.

  READ ENTITIES OF zr_kf_ec_claim IN LOCAL MODE
    ENTITY zr_kf_ec_line
      FIELDS ( line_number expense_date )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_lines)

    ENTITY zr_kf_ec_line BY \_claim
      FROM CORRESPONDING #( keys )
      LINK DATA(lt_links).

  LOOP AT lt_lines INTO DATA(ls_line).

    IF ls_line-expense_date IS INITIAL.
      CONTINUE.
    ENDIF.

    DATA(ls_link) = lt_links[
      source-%tky = ls_line-%tky
    ].

    DATA(ls_claim_key) = ls_link-target.

    READ ENTITIES OF zr_kf_ec_claim IN LOCAL MODE
      ENTITY zr_kf_ec_claim
      FIELDS ( trip_start_date trip_end_date )
      WITH VALUE #(
        ( %tky = ls_claim_key-%tky )
      )
      RESULT DATA(lt_claims).

    CHECK lt_claims IS NOT INITIAL.

    DATA(ls_claim) = lt_claims[ 1 ].

    IF ls_claim-trip_start_date IS NOT INITIAL
       AND ls_claim-trip_end_date IS NOT INITIAL
       AND
       ( ls_line-expense_date < ls_claim-trip_start_date
         OR
         ls_line-expense_date > ls_claim-trip_end_date ).

      APPEND VALUE #(
        %tky = ls_line-%tky
      ) TO failed-zr_kf_ec_line.

      DATA(lv_expense_date) =
        |{ ls_line-expense_date DATE = USER }|.

      DATA(lv_message) =
        |Line { ls_line-line_number }: expense date { lv_expense_date } is outside the trip dates.|.

      APPEND VALUE #(
        %tky = ls_line-%tky

        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = lv_message
        )

        %element-expense_date = if_abap_behv=>mk-on

      ) TO reported-zr_kf_ec_line.

    ENDIF.

  ENDLOOP.

ENDMETHOD.

  METHOD validateCategory.

  READ ENTITIES OF zr_kf_ec_claim IN LOCAL MODE
    ENTITY zr_kf_ec_line
    FIELDS ( line_number category description )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_lines).

  LOOP AT lt_lines INTO DATA(ls_line).

    IF ls_line-category = 'OTHER'
       AND ls_line-description IS INITIAL.

      APPEND VALUE #(
        %tky = ls_line-%tky
      ) TO failed-zr_kf_ec_line.

      DATA(lv_message) =
        |Line { ls_line-line_number }: a description is required for category Other.|.

      APPEND VALUE #(
        %tky = ls_line-%tky

        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = lv_message
        )

        %element-description = if_abap_behv=>mk-on

      ) TO reported-zr_kf_ec_line.

    ENDIF.

  ENDLOOP.

ENDMETHOD.
  METHOD validateRequiredReceipt.

  READ ENTITIES OF zr_kf_ec_claim IN LOCAL MODE
    ENTITY zr_kf_ec_line
    FIELDS (
      line_number
      receipt_required
      number_of_receipts
    )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_lines).

  LOOP AT lt_lines INTO DATA(ls_line).

    IF ls_line-receipt_required = abap_true
       AND ls_line-number_of_receipts = 0.

      APPEND VALUE #(
        %tky = ls_line-%tky
      ) TO failed-zr_kf_ec_line.

      DATA(lv_message) =
        |Line { ls_line-line_number }: a receipt is required for amounts above EUR 50.00.|.

      APPEND VALUE #(
        %tky = ls_line-%tky

        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = lv_message
        )

        %element-receipt_required = if_abap_behv=>mk-on

      ) TO reported-zr_kf_ec_line.

    ENDIF.

  ENDLOOP.

ENDMETHOD.

METHOD validateMealsLimit.

  " Read the lines that triggered the validation
  " and get the link from each Line to its parent Claim
  READ ENTITIES OF zr_kf_ec_claim IN LOCAL MODE

    ENTITY zr_kf_ec_line
      FIELDS (
        line_number
        expense_date
        category
      )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_changed_lines)

    ENTITY zr_kf_ec_line BY \_claim
      FROM CORRESPONDING #( keys )
      LINK DATA(lt_links).


  LOOP AT lt_changed_lines INTO DATA(ls_changed_line).

    " BR-08 only applies to MEALS
    CHECK ls_changed_line-category = 'MEALS'.

    " Ignore blank dates for now.
    " Mandatory fields will be handled later.
    CHECK ls_changed_line-expense_date IS NOT INITIAL.


    " Find the parent Claim of this Line
    READ TABLE lt_links
      INTO DATA(ls_link)
      WITH KEY source-%tky = ls_changed_line-%tky.

    " If no parent link was found, don't continue
    CHECK sy-subrc = 0.


    " Target of _claim = parent Claim
    DATA(ls_claim_key) = ls_link-target.


    " Read ALL Expense Lines belonging to this Claim
    READ ENTITIES OF zr_kf_ec_claim IN LOCAL MODE
      ENTITY zr_kf_ec_claim BY \_line

      FIELDS (
        line_number
        expense_date
        category
        amount
      )

      WITH VALUE #(
        ( %tky = ls_claim_key-%tky )
      )

      RESULT DATA(lt_claim_lines).


    " Start the Meals total at zero
    DATA lv_meals_total TYPE zkf_ec_line-amount.
    CLEAR lv_meals_total.


    " Sum MEALS only for the same Expense Date
    LOOP AT lt_claim_lines INTO DATA(ls_claim_line)
      WHERE category = 'MEALS'
        AND expense_date = ls_changed_line-expense_date.

      lv_meals_total =
        lv_meals_total + ls_claim_line-amount.

    ENDLOOP.


    " Valid if total is EUR 75.00 or lower
    CHECK lv_meals_total > 75.


    " If we reach here, BR-08 failed
    APPEND VALUE #(
      %tky = ls_changed_line-%tky
    ) TO failed-zr_kf_ec_line.


    DATA(lv_expense_date) =
      |{ ls_changed_line-expense_date DATE = USER }|.


    DATA(lv_message) =
      |Line { ls_changed_line-line_number }: meals exceed EUR 75.00 for { lv_expense_date }.|.


    APPEND VALUE #(
      %tky = ls_changed_line-%tky

      %msg = new_message_with_text(
        severity = if_abap_behv_message=>severity-error
        text     = lv_message
      )

      %element-amount = if_abap_behv=>mk-on

    ) TO reported-zr_kf_ec_line.


    " Avoid reporting the same daily Meals violation
    " once for every changed Line
    EXIT.

  ENDLOOP.

ENDMETHOD.

  METHOD validateHotelPerDay.

  READ ENTITIES OF zr_kf_ec_claim IN LOCAL MODE

    ENTITY zr_kf_ec_line
      FIELDS (
        line_number
        expense_date
        category
      )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_changed_lines)

    ENTITY zr_kf_ec_line BY \_claim
      FROM CORRESPONDING #( keys )
      LINK DATA(lt_links).


  LOOP AT lt_changed_lines INTO DATA(ls_changed_line).

    " This rule only applies to HOTEL lines
    CHECK ls_changed_line-category = 'HOTEL'.

    " Ignore missing dates until we enable mandatory fields
    CHECK ls_changed_line-expense_date IS NOT INITIAL.


    " Find this Line's parent Claim
    READ TABLE lt_links
      INTO DATA(ls_link)
      WITH KEY source-%tky = ls_changed_line-%tky.

    CHECK sy-subrc = 0.

    DATA(ls_claim_key) = ls_link-target.


    " Read all Expense Lines belonging to the same Claim
    READ ENTITIES OF zr_kf_ec_claim IN LOCAL MODE
      ENTITY zr_kf_ec_claim BY \_line

      FIELDS (
        line_number
        expense_date
        category
      )

      WITH VALUE #(
        ( %tky = ls_claim_key-%tky )
      )

      RESULT DATA(lt_claim_lines).


    DATA lv_hotel_count TYPE i.


    " Count HOTEL lines on this same date
    LOOP AT lt_claim_lines INTO DATA(ls_claim_line)
      WHERE category = 'HOTEL'
        AND expense_date = ls_changed_line-expense_date.

      lv_hotel_count = lv_hotel_count + 1.

    ENDLOOP.


    " 0 or 1 Hotel is valid.
    " Continue only when count > 1.
    CHECK lv_hotel_count > 1.


    APPEND VALUE #(
      %tky = ls_changed_line-%tky
    ) TO failed-zr_kf_ec_line.


    DATA(lv_expense_date) =
      |{ ls_changed_line-expense_date DATE = USER }|.


    DATA(lv_message) =
      |Line { ls_changed_line-line_number }: only one Hotel expense is allowed for { lv_expense_date }.|.


    APPEND VALUE #(
      %tky = ls_changed_line-%tky

      %msg = new_message_with_text(
        severity = if_abap_behv_message=>severity-error
        text     = lv_message
      )

      %element-category     = if_abap_behv=>mk-on
      %element-expense_date = if_abap_behv=>mk-on

    ) TO reported-zr_kf_ec_line.


    " One message for the daily violation is enough
    EXIT.

  ENDLOOP.

ENDMETHOD.

ENDCLASS.

CLASS lhc_ZR_KF_EC_CLAIM DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      keys REQUEST requested_authorizations FOR zr_kf_ec_claim RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      REQUEST requested_authorizations FOR zr_kf_ec_claim RESULT result.
    METHODS generate_claimno FOR DETERMINE ON MODIFY
      keys FOR zr_kf_ec_claim~generate_claimno.
    METHODS setdefaults FOR DETERMINE ON MODIFY
      keys FOR zr_kf_ec_claim~setdefaults.
    METHODS validatetripdates FOR VALIDATE ON SAVE
      keys FOR zr_kf_ec_claim~validatetripdates.
    METHODS get_instance_features FOR INSTANCE FEATURES
      keys REQUEST requested_features FOR zr_kf_ec_claim RESULT result.


ENDCLASS.

CLASS lhc_ZR_KF_EC_CLAIM IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.


  METHOD generate_claimno.
  DATA lv_number TYPE cl_numberrange_runtime=>nr_number.
        TRY.
        cl_numberrange_runtime=>number_get(
        EXPORTING
        nr_range_nr = '01'
        object = 'ZKF_EC_NR'
        IMPORTING
        number = lv_number
        ).
        MODIFY ENTITIES OF  zr_kf_ec_claim   IN LOCAL MODE
        ENTITY zr_kf_ec_claim
        UPDATE FIELDS ( claim_number  )
        WITH VALUE #(
        FOR key IN keys
        (
        %tky = key-%tky
        claim_number = lv_number
        )
        ).
        CATCH cx_number_ranges.
        " Error handling
        ENDTRY.
  ENDMETHOD.

  METHOD setDefaults.

  MODIFY ENTITIES OF zr_kf_ec_claim IN LOCAL MODE
    ENTITY zr_kf_ec_claim
    UPDATE FIELDS ( currency_code status )
    WITH VALUE #(
      FOR key IN keys
      (
        %tky          = key-%tky
        currency_code = 'EUR'
        status        = 'Open'
      )
    ).

ENDMETHOD.

METHOD validateTripDates.

  READ ENTITIES OF zr_kf_ec_claim IN LOCAL MODE
    ENTITY zr_kf_ec_claim
    FIELDS ( trip_start_date trip_end_date )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_claims).

  LOOP AT lt_claims INTO DATA(ls_claim).

    IF ls_claim-trip_start_date IS NOT INITIAL
       AND ls_claim-trip_end_date IS NOT INITIAL
       AND ls_claim-trip_end_date < ls_claim-trip_start_date.

      DATA(lv_start_date) =
        |{ ls_claim-trip_start_date DATE = USER }|.

      DATA(lv_end_date) =
        |{ ls_claim-trip_end_date DATE = USER }|.

      DATA(lv_message) =
        |Trip end date { lv_end_date } is before trip start date { lv_start_date }.|.

      APPEND VALUE #(
        %tky = ls_claim-%tky
      ) TO failed-zr_kf_ec_claim.

      APPEND VALUE #(
        %tky = ls_claim-%tky

        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = lv_message
        )

        %element-trip_end_date = if_abap_behv=>mk-on

      ) TO reported-zr_kf_ec_claim.

    ENDIF.

  ENDLOOP.

ENDMETHOD.

  METHOD get_instance_features.

  READ ENTITIES OF zr_kf_ec_claim IN LOCAL MODE
    ENTITY zr_kf_ec_claim
      FIELDS ( currency_code )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_claims).

  LOOP AT lt_claims INTO DATA(ls_claim).

    READ ENTITIES OF zr_kf_ec_claim IN LOCAL MODE
      ENTITY zr_kf_ec_claim BY \_line
        FIELDS ( line_uuid )
        WITH VALUE #(
          ( %tky = ls_claim-%tky )
        )
        RESULT DATA(lt_lines).

    APPEND VALUE #(
      %tky = ls_claim-%tky

      %field-currency_code = COND #(

        WHEN lt_lines IS INITIAL
        THEN if_abap_behv=>fc-f-unrestricted

        ELSE if_abap_behv=>fc-f-read_only

      )

    ) TO result.

  ENDLOOP.

ENDMETHOD.

ENDCLASS.
