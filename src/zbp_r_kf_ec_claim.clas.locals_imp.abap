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

  APPEND VALUE #(
    %tky = ls_receipt-%tky
  ) TO failed-zr_kf_ec_receipt.

  APPEND VALUE #(
    %tky = ls_receipt-%tky

    %msg = new_message_with_text(
      severity = if_abap_behv_message=>severity-error
      text     = 'Receipt File is required.'
    )

    %element-receipt_file = if_abap_behv=>mk-on

  ) TO reported-zr_kf_ec_receipt.

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
    METHODS validateRequiredLineFields FOR VALIDATE ON SAVE
      keys FOR ZR_KF_EC_LINE~validateRequiredLineFields.


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

  METHOD validateRequiredLineFields.

  READ ENTITIES OF zr_kf_ec_claim IN LOCAL MODE
    ENTITY zr_kf_ec_line
    FIELDS (
      line_number
      expense_date
      category
      amount
    )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_lines).


  LOOP AT lt_lines INTO DATA(ls_line).

    " Expense Date
    IF ls_line-expense_date IS INITIAL.

      APPEND VALUE #(
        %tky = ls_line-%tky
      ) TO failed-zr_kf_ec_line.

      APPEND VALUE #(
        %tky = ls_line-%tky

        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = |Line { ls_line-line_number }: Expense Date is required.|
        )

        %element-expense_date = if_abap_behv=>mk-on

      ) TO reported-zr_kf_ec_line.

    ENDIF.


    " Category
    IF ls_line-category IS INITIAL.

      APPEND VALUE #(
        %tky = ls_line-%tky
      ) TO failed-zr_kf_ec_line.

      APPEND VALUE #(
        %tky = ls_line-%tky

        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = |Line { ls_line-line_number }: Category is required.|
        )

        %element-category = if_abap_behv=>mk-on

      ) TO reported-zr_kf_ec_line.

    ENDIF.


    " Amount
    IF ls_line-amount IS INITIAL.

      APPEND VALUE #(
        %tky = ls_line-%tky
      ) TO failed-zr_kf_ec_line.

      APPEND VALUE #(
        %tky = ls_line-%tky

        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = |Line { ls_line-line_number }: Amount is required.|
        )

        %element-amount = if_abap_behv=>mk-on

      ) TO reported-zr_kf_ec_line.

    ENDIF.

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
    METHODS submit FOR MODIFY
      keys FOR ACTION zr_kf_ec_claim~submit RESULT result.
    METHODS withdraw FOR MODIFY
      keys FOR ACTION zr_kf_ec_claim~withdraw RESULT result.
    METHODS approve FOR MODIFY
      keys FOR ACTION zr_kf_ec_claim~approve RESULT result.
    METHODS reject FOR MODIFY
      keys FOR ACTION zr_kf_ec_claim~reject RESULT result.
    METHODS markaspaid FOR MODIFY
      keys FOR ACTION zr_kf_ec_claim~markaspaid RESULT result.
    METHODS copyclaim FOR MODIFY
      keys FOR ACTION zr_kf_ec_claim~copyclaim RESULT result.
    METHODS massapprove FOR MODIFY
      keys FOR ACTION zr_kf_ec_claim~massapprove.
    METHODS validaterequiredfields FOR VALIDATE ON SAVE
      keys FOR zr_kf_ec_claim~validaterequiredfields.


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
      FIELDS (
        status
        currency_code
      )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_claims).


  LOOP AT lt_claims INTO DATA(ls_claim).

    " Read Expense Lines.
    " Currency is editable only when there are no Lines.
    READ ENTITIES OF zr_kf_ec_claim IN LOCAL MODE
      ENTITY zr_kf_ec_claim BY \_line
        FIELDS ( line_uuid )
        WITH VALUE #(
          ( %tky = ls_claim-%tky )
        )
        RESULT DATA(lt_lines).


    " Open and Rejected Claims are editable.
    DATA(lv_claim_editable) = xsdbool(
      ls_claim-status = 'Open'
      OR
      ls_claim-status = 'Rejected'
    ).


    APPEND VALUE #(
      %tky = ls_claim-%tky


      " ===========================================
      " CLAIM FIELD CONTROL
      " Open / Rejected -> mandatory
      " Other statuses -> readonly
      " ===========================================

      %field-employee_name = COND #(
        WHEN lv_claim_editable = abap_true
          THEN if_abap_behv=>fc-f-mandatory
        ELSE
          if_abap_behv=>fc-f-read_only
      )

      %field-trip_purpose = COND #(
        WHEN lv_claim_editable = abap_true
          THEN if_abap_behv=>fc-f-mandatory
        ELSE
          if_abap_behv=>fc-f-read_only
      )

      %field-destination_country = COND #(
        WHEN lv_claim_editable = abap_true
          THEN if_abap_behv=>fc-f-mandatory
        ELSE
          if_abap_behv=>fc-f-read_only
      )

      %field-trip_start_date = COND #(
        WHEN lv_claim_editable = abap_true
          THEN if_abap_behv=>fc-f-mandatory
        ELSE
          if_abap_behv=>fc-f-read_only
      )

      %field-trip_end_date = COND #(
        WHEN lv_claim_editable = abap_true
          THEN if_abap_behv=>fc-f-mandatory
        ELSE
          if_abap_behv=>fc-f-read_only
      )


      " Currency:
      " Open / Rejected + no Lines -> mandatory/editable
      " Otherwise -> readonly
      %field-currency_code = COND #(
        WHEN lv_claim_editable = abap_true
         AND lt_lines IS INITIAL
          THEN if_abap_behv=>fc-f-mandatory
        ELSE
          if_abap_behv=>fc-f-read_only
      )


      " ===========================================
      " WORKFLOW ACTIONS
      " ===========================================

      %action-Submit = COND #(
        WHEN ls_claim-status = 'Open'
          OR ls_claim-status = 'Rejected'
          THEN if_abap_behv=>fc-o-enabled
        ELSE
          if_abap_behv=>fc-o-disabled
      )

      %action-Withdraw = COND #(
        WHEN ls_claim-status = 'Submitted'
          THEN if_abap_behv=>fc-o-enabled
        ELSE
          if_abap_behv=>fc-o-disabled
      )

      %action-Approve = COND #(
        WHEN ls_claim-status = 'Submitted'
          THEN if_abap_behv=>fc-o-enabled
        ELSE
          if_abap_behv=>fc-o-disabled
      )

      %action-Reject = COND #(
        WHEN ls_claim-status = 'Submitted'
          THEN if_abap_behv=>fc-o-enabled
        ELSE
          if_abap_behv=>fc-o-disabled
      )

      %action-MarkAsPaid = COND #(
        WHEN ls_claim-status = 'Approved'
          THEN if_abap_behv=>fc-o-enabled
        ELSE
          if_abap_behv=>fc-o-disabled
      )


      " ===========================================
      " STANDARD OPERATIONS / DRAFT EDIT
      " ===========================================

      %update = COND #(
        WHEN lv_claim_editable = abap_true
          THEN if_abap_behv=>fc-o-enabled
        ELSE
          if_abap_behv=>fc-o-disabled
      )

      %delete = COND #(
        WHEN lv_claim_editable = abap_true
          THEN if_abap_behv=>fc-o-enabled
        ELSE
          if_abap_behv=>fc-o-disabled
      )

      %action-Edit = COND #(
        WHEN lv_claim_editable = abap_true
          THEN if_abap_behv=>fc-o-enabled
        ELSE
          if_abap_behv=>fc-o-disabled
      )

    ) TO result.

  ENDLOOP.

ENDMETHOD.
  METHOD Submit.

  READ ENTITIES OF zr_kf_ec_claim IN LOCAL MODE

    ENTITY zr_kf_ec_claim
      FIELDS (
        status
        trip_end_date
      )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_claims)

    ENTITY zr_kf_ec_claim BY \_line
      FROM CORRESPONDING #( keys )
      LINK DATA(lt_line_links).


  LOOP AT lt_claims INTO DATA(ls_claim).

    DATA(lv_submit_failed) = abap_false.


    " Submit is only allowed from Open or Rejected
    IF ls_claim-status <> 'Open'
       AND ls_claim-status <> 'Rejected'.

      lv_submit_failed = abap_true.

      APPEND VALUE #(
        %tky = ls_claim-%tky

        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = 'Only Open or Rejected claims can be submitted.'
        )

        %action-Submit = if_abap_behv=>mk-on

      ) TO reported-zr_kf_ec_claim.

    ENDIF.


    " BR-11: Claim must contain at least one Expense Line
    IF NOT line_exists(
      lt_line_links[
        source-%tky = ls_claim-%tky
      ]
    ).

      lv_submit_failed = abap_true.

      APPEND VALUE #(
        %tky = ls_claim-%tky

        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = 'Submit refused: the claim must contain at least one expense line.'
        )

        %action-Submit = if_abap_behv=>mk-on

      ) TO reported-zr_kf_ec_claim.

    ENDIF.


    " BR-11: Trip must have ended
    IF ls_claim-trip_end_date IS INITIAL
       OR ls_claim-trip_end_date > cl_abap_context_info=>get_system_date( ).

      lv_submit_failed = abap_true.

      APPEND VALUE #(
        %tky = ls_claim-%tky

        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = 'Submit refused: the trip must have ended.'
        )

        %element-trip_end_date = if_abap_behv=>mk-on
        %action-Submit         = if_abap_behv=>mk-on

      ) TO reported-zr_kf_ec_claim.

    ENDIF.


    " Report every reason, then fail the action once
    IF lv_submit_failed = abap_true.

      APPEND VALUE #(
        %tky = ls_claim-%tky
      ) TO failed-zr_kf_ec_claim.

      CONTINUE.

    ENDIF.


    " BR-11 passed: perform the transition
    MODIFY ENTITIES OF zr_kf_ec_claim IN LOCAL MODE
      ENTITY zr_kf_ec_claim
        UPDATE FIELDS (
          status
          submitted_on
          rejection_reason
          decision_date
        )
        WITH VALUE #(
          (
            %tky             = ls_claim-%tky
            status           = 'Submitted'
            submitted_on     = cl_abap_context_info=>get_system_date( )
            rejection_reason = ''
            decision_date    = '00000000'
          )
        )
        FAILED DATA(lt_update_failed)
        REPORTED DATA(lt_update_reported).

    APPEND LINES OF lt_update_failed-zr_kf_ec_claim
      TO failed-zr_kf_ec_claim.

    APPEND LINES OF lt_update_reported-zr_kf_ec_claim
      TO reported-zr_kf_ec_claim.

  ENDLOOP.


  " Return the updated instances to Fiori
  READ ENTITIES OF zr_kf_ec_claim IN LOCAL MODE
    ENTITY zr_kf_ec_claim
      ALL FIELDS
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_result_claims).


  result = VALUE #(
    FOR ls_result_claim IN lt_result_claims
    (
      %tky   = ls_result_claim-%tky
      %param = ls_result_claim
    )
  ).

ENDMETHOD.
  METHOD Withdraw.

  READ ENTITIES OF zr_kf_ec_claim IN LOCAL MODE
    ENTITY zr_kf_ec_claim
      FIELDS ( status )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_claims).


  LOOP AT lt_claims INTO DATA(ls_claim).

    " Withdraw is only allowed for Submitted claims
    IF ls_claim-status <> 'Submitted'.

      APPEND VALUE #(
        %tky = ls_claim-%tky
      ) TO failed-zr_kf_ec_claim.

      APPEND VALUE #(
        %tky = ls_claim-%tky

        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = 'Only Submitted claims can be withdrawn.'
        )

        %action-Withdraw = if_abap_behv=>mk-on

      ) TO reported-zr_kf_ec_claim.

      CONTINUE.

    ENDIF.


    " FR-202:
    " Submitted -> Open
    " Submitted On is cleared
    MODIFY ENTITIES OF zr_kf_ec_claim IN LOCAL MODE
      ENTITY zr_kf_ec_claim
        UPDATE FIELDS (
          status
          submitted_on
        )
        WITH VALUE #(
          (
            %tky         = ls_claim-%tky
            status       = 'Open'
            submitted_on = '00000000'
          )
        ).

  ENDLOOP.


  " Return the updated Claim to Fiori
  READ ENTITIES OF zr_kf_ec_claim IN LOCAL MODE
    ENTITY zr_kf_ec_claim
      ALL FIELDS
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_result_claims).


  result = VALUE #(
    FOR ls_result_claim IN lt_result_claims
    (
      %tky   = ls_result_claim-%tky
      %param = ls_result_claim
    )
  ).

ENDMETHOD.

  METHOD Approve.

  READ ENTITIES OF zr_kf_ec_claim IN LOCAL MODE
    ENTITY zr_kf_ec_claim
      FIELDS (
        status
        total_amount
      )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_claims).


  LOOP AT lt_claims INTO DATA(ls_claim).

    " Approve only works for Submitted claims
    IF ls_claim-status <> 'Submitted'.

      APPEND VALUE #(
        %tky = ls_claim-%tky
      ) TO failed-zr_kf_ec_claim.

      APPEND VALUE #(
        %tky = ls_claim-%tky

        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = 'Only Submitted claims can be approved.'
        )

        %action-Approve = if_abap_behv=>mk-on

      ) TO reported-zr_kf_ec_claim.

      CONTINUE.

    ENDIF.


    " BR-12
    " Anything above EUR 5,000.00 requires Director approval
    IF ls_claim-total_amount > 5000.

      APPEND VALUE #(
        %tky = ls_claim-%tky
      ) TO failed-zr_kf_ec_claim.

      DATA(lv_message) =
        |Approve refused: total amount exceeds EUR 5,000.00.|.

      APPEND VALUE #(
        %tky = ls_claim-%tky

        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = lv_message
        )

        %element-total_amount = if_abap_behv=>mk-on
        %action-Approve       = if_abap_behv=>mk-on

      ) TO reported-zr_kf_ec_claim.

      CONTINUE.

    ENDIF.


    " All checks passed:
    " Submitted -> Approved
    MODIFY ENTITIES OF zr_kf_ec_claim IN LOCAL MODE
      ENTITY zr_kf_ec_claim
        UPDATE FIELDS (
          status
          decision_date
        )
        WITH VALUE #(
          (
            %tky          = ls_claim-%tky
            status        = 'Approved'
            decision_date = cl_abap_context_info=>get_system_date( )
          )
        ).

  ENDLOOP.


  " Return updated Claim to Fiori
  READ ENTITIES OF zr_kf_ec_claim IN LOCAL MODE
    ENTITY zr_kf_ec_claim
      ALL FIELDS
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_result_claims).


  result = VALUE #(
    FOR ls_result_claim IN lt_result_claims
    (
      %tky   = ls_result_claim-%tky
      %param = ls_result_claim
    )
  ).

ENDMETHOD.

  METHOD Reject.

  READ ENTITIES OF zr_kf_ec_claim IN LOCAL MODE
    ENTITY zr_kf_ec_claim
      FIELDS ( status )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_claims).


  LOOP AT keys INTO DATA(ls_key).

    READ TABLE lt_claims
      INTO DATA(ls_claim)
      WITH KEY %tky = ls_key-%tky.

    CHECK sy-subrc = 0.


    " Reject is allowed only for Submitted Claims
    IF ls_claim-status <> 'Submitted'.

      APPEND VALUE #(
        %tky = ls_claim-%tky
      ) TO failed-zr_kf_ec_claim.

      APPEND VALUE #(
        %tky = ls_claim-%tky

        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = 'Only Submitted claims can be rejected.'
        )

        %action-Reject = if_abap_behv=>mk-on

      ) TO reported-zr_kf_ec_claim.

      CONTINUE.

    ENDIF.


    " Read the reason entered in the popup
    DATA(lv_rejection_reason) =
      CONV string( ls_key-%param-rejection_reason ).

    " Ignore accidental spaces at the beginning and end
    SHIFT lv_rejection_reason LEFT
      DELETING LEADING space.

    SHIFT lv_rejection_reason RIGHT
      DELETING TRAILING space.


    " BR-13:
    " Rejection reason must contain at least 15 characters
    IF strlen( lv_rejection_reason ) < 15.

      APPEND VALUE #(
        %tky = ls_claim-%tky
      ) TO failed-zr_kf_ec_claim.

      APPEND VALUE #(
        %tky = ls_claim-%tky

        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = 'Reject refused: the rejection reason must contain at least 15 characters.'
        )

        %action-Reject = if_abap_behv=>mk-on

      ) TO reported-zr_kf_ec_claim.

      CONTINUE.

    ENDIF.


    " All checks passed:
    " Submitted -> Rejected
    MODIFY ENTITIES OF zr_kf_ec_claim IN LOCAL MODE
      ENTITY zr_kf_ec_claim
        UPDATE FIELDS (
          status
          rejection_reason
          decision_date
        )
        WITH VALUE #(
          (
            %tky             = ls_claim-%tky
            status           = 'Rejected'
            rejection_reason = lv_rejection_reason
            decision_date    =
              cl_abap_context_info=>get_system_date( )
          )
        )
        FAILED DATA(lt_update_failed)
        REPORTED DATA(lt_update_reported).


    APPEND LINES OF
      lt_update_failed-zr_kf_ec_claim
      TO failed-zr_kf_ec_claim.

    APPEND LINES OF
      lt_update_reported-zr_kf_ec_claim
      TO reported-zr_kf_ec_claim.

  ENDLOOP.


  " Return the updated instances to Fiori
  READ ENTITIES OF zr_kf_ec_claim IN LOCAL MODE
    ENTITY zr_kf_ec_claim
      ALL FIELDS
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_result_claims).


  result = VALUE #(
    FOR ls_result_claim IN lt_result_claims
    (
      %tky   = ls_result_claim-%tky
      %param = ls_result_claim
    )
  ).

ENDMETHOD.

  METHOD MarkAsPaid.

  READ ENTITIES OF zr_kf_ec_claim IN LOCAL MODE
    ENTITY zr_kf_ec_claim
      FIELDS (
        status
        decision_date
      )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_claims).


  LOOP AT keys INTO DATA(ls_key).

    READ TABLE lt_claims
      INTO DATA(ls_claim)
      WITH KEY %tky = ls_key-%tky.

    CHECK sy-subrc = 0.


    " Mark as Paid is only possible from Approved
    IF ls_claim-status <> 'Approved'.

      APPEND VALUE #(
        %tky = ls_claim-%tky
      ) TO failed-zr_kf_ec_claim.

      APPEND VALUE #(
        %tky = ls_claim-%tky

        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = 'Only Approved claims can be marked as Paid.'
        )

        %action-MarkAsPaid = if_abap_behv=>mk-on

      ) TO reported-zr_kf_ec_claim.

      CONTINUE.

    ENDIF.


    DATA(lv_payment_reference) =
      CONV string( ls_key-%param-payment_reference ).

    DATA(lv_payment_date) =
      ls_key-%param-payment_date.


    " Remove accidental spaces
    SHIFT lv_payment_reference LEFT
      DELETING LEADING space.

    SHIFT lv_payment_reference RIGHT
      DELETING TRAILING space.


    " BR-14: Payment Reference is required
    IF lv_payment_reference IS INITIAL.

      APPEND VALUE #(
        %tky = ls_claim-%tky
      ) TO failed-zr_kf_ec_claim.

      APPEND VALUE #(
        %tky = ls_claim-%tky

        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = 'Payment reference is required.'
        )

        %action-MarkAsPaid = if_abap_behv=>mk-on

      ) TO reported-zr_kf_ec_claim.

      CONTINUE.

    ENDIF.


    " For now, if blank, use today.
    " Later we can default this directly in the popup.
    IF lv_payment_date IS INITIAL.

      lv_payment_date =
        cl_abap_context_info=>get_system_date( ).

    ENDIF.


    " BR-14: Payment Date cannot be in the future
    IF lv_payment_date >
       cl_abap_context_info=>get_system_date( ).

      APPEND VALUE #(
        %tky = ls_claim-%tky
      ) TO failed-zr_kf_ec_claim.

      APPEND VALUE #(
        %tky = ls_claim-%tky

        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = 'Payment date must not be in the future.'
        )

        %action-MarkAsPaid = if_abap_behv=>mk-on

      ) TO reported-zr_kf_ec_claim.

      CONTINUE.

    ENDIF.


    " BR-14:
    " Payment Date cannot be before Decision Date
    IF ls_claim-decision_date IS NOT INITIAL
       AND lv_payment_date < ls_claim-decision_date.

      APPEND VALUE #(
        %tky = ls_claim-%tky
      ) TO failed-zr_kf_ec_claim.

      APPEND VALUE #(
        %tky = ls_claim-%tky

        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = 'Payment date must not be before the decision date.'
        )

        %action-MarkAsPaid = if_abap_behv=>mk-on

      ) TO reported-zr_kf_ec_claim.

      CONTINUE.

    ENDIF.


    " BR-14 passed
    MODIFY ENTITIES OF zr_kf_ec_claim IN LOCAL MODE
      ENTITY zr_kf_ec_claim
        UPDATE FIELDS (
          status
          payment_reference
          payment_date
        )
        WITH VALUE #(
          (
            %tky              = ls_claim-%tky
            status            = 'Paid'
            payment_reference = lv_payment_reference
            payment_date      = lv_payment_date
          )
        ).

  ENDLOOP.


  " Return updated instances
  READ ENTITIES OF zr_kf_ec_claim IN LOCAL MODE
    ENTITY zr_kf_ec_claim
      ALL FIELDS
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_result_claims).


  result = VALUE #(
    FOR ls_result_claim IN lt_result_claims
    (
      %tky   = ls_result_claim-%tky
      %param = ls_result_claim
    )
  ).

ENDMETHOD.

  METHOD CopyClaim.

  " Read the original Claims selected for Copy
  READ ENTITIES OF zr_kf_ec_claim IN LOCAL MODE
    ENTITY zr_kf_ec_claim
      ALL FIELDS
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_source_claims).


  LOOP AT lt_source_claims INTO DATA(ls_source_claim).

    DATA(lv_claim_index) = sy-tabix.
    DATA(lv_copy_failed) = abap_false.

    DATA(lv_claim_cid) =
      |COPY_CLAIM_{ lv_claim_index }|.

    DATA lv_copy_purpose TYPE zkf_ec_claim-trip_purpose.

    lv_copy_purpose =
      |Copy of { ls_source_claim-trip_purpose }|.


    " =========================================================
    " STEP 1: CREATE THE NEW ROOT CLAIM
    " =========================================================

    MODIFY ENTITIES OF zr_kf_ec_claim IN LOCAL MODE

      ENTITY zr_kf_ec_claim

        CREATE FIELDS (
          employee_name
          trip_purpose
          destination_country
          trip_start_date
          trip_end_date
          currency_code
        )

        WITH VALUE #(
          (
            %cid                = lv_claim_cid
            employee_name       = ls_source_claim-employee_name
            trip_purpose        = lv_copy_purpose
            destination_country = ls_source_claim-destination_country
            trip_start_date     = ls_source_claim-trip_start_date
            trip_end_date       = ls_source_claim-trip_end_date
            currency_code       = ls_source_claim-currency_code
          )
        )

        MAPPED DATA(lt_mapped_claim)
        FAILED DATA(lt_failed_claim)
        REPORTED DATA(lt_reported_claim).


    " Stop if the new Claim could not be created
    IF lt_failed_claim-zr_kf_ec_claim IS NOT INITIAL
       OR lt_mapped_claim-zr_kf_ec_claim IS INITIAL.

      APPEND VALUE #(
        %tky = ls_source_claim-%tky
      ) TO failed-zr_kf_ec_claim.

      APPEND VALUE #(
        %tky = ls_source_claim-%tky

        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = 'The Claim copy could not be created.'
        )

        %action-CopyClaim = if_abap_behv=>mk-on

      ) TO reported-zr_kf_ec_claim.

      CONTINUE.

    ENDIF.


    " Get the transactional key of the new Claim
    DATA(ls_new_claim_key) =
      lt_mapped_claim-zr_kf_ec_claim[
        %cid = lv_claim_cid
      ].


    " setDefaults runs on Claim creation and sets EUR.
    " Copy the original Claim currency again afterwards.
    MODIFY ENTITIES OF zr_kf_ec_claim IN LOCAL MODE

      ENTITY zr_kf_ec_claim

        UPDATE FIELDS ( currency_code )

        WITH VALUE #(
          (
            %tky          = ls_new_claim_key-%tky
            currency_code = ls_source_claim-currency_code
          )
        ).


    " =========================================================
    " STEP 2: READ THE ORIGINAL EXPENSE LINES
    " =========================================================

    READ ENTITIES OF zr_kf_ec_claim IN LOCAL MODE

      ENTITY zr_kf_ec_claim BY \_line

        ALL FIELDS

        WITH VALUE #(
          ( %tky = ls_source_claim-%tky )
        )

        RESULT DATA(lt_source_lines).


    DATA lv_line_index TYPE i.
    DATA lv_receipt_index TYPE i.


    LOOP AT lt_source_lines INTO DATA(ls_source_line).

      lv_line_index = lv_line_index + 1.

      DATA(lv_line_cid) =
        |COPY_LINE_{ lv_claim_index }_{ lv_line_index }|.


      " =======================================================
      " STEP 3: READ THE ORIGINAL RECEIPTS FOR THIS LINE
      " =======================================================

      READ ENTITIES OF zr_kf_ec_claim IN LOCAL MODE

        ENTITY zr_kf_ec_line BY \_RECEIPT

          ALL FIELDS

          WITH VALUE #(
            ( %tky = ls_source_line-%tky )
          )

          RESULT DATA(lt_source_receipts).


      " =======================================================
      " STEP 4: CREATE THE COPIED EXPENSE LINE
      " =======================================================

      MODIFY ENTITIES OF zr_kf_ec_claim IN LOCAL MODE

        ENTITY zr_kf_ec_claim

          CREATE BY \_line

          FIELDS (
            expense_date
            category
            description
            amount
          )

          WITH VALUE #(
            (
              %tky = ls_new_claim_key-%tky

              %target = VALUE #(
                (
                  %cid         = lv_line_cid
                  expense_date = ls_source_line-expense_date
                  category     = ls_source_line-category
                  description  = ls_source_line-description
                  amount       = ls_source_line-amount
                )
              )
            )
          )

          MAPPED DATA(lt_mapped_line)
          FAILED DATA(lt_failed_line)
          REPORTED DATA(lt_reported_line).


      IF lt_failed_line-zr_kf_ec_line IS NOT INITIAL
         OR lt_mapped_line-zr_kf_ec_line IS INITIAL.

        lv_copy_failed = abap_true.
        EXIT.

      ENDIF.


      " Get the transactional key of the copied Line
      DATA(ls_new_line_key) =
        lt_mapped_line-zr_kf_ec_line[
          %cid = lv_line_cid
        ].


      " =======================================================
      " STEP 5: CREATE COPIED RECEIPTS FOR THIS NEW LINE
      " =======================================================

      LOOP AT lt_source_receipts INTO DATA(ls_source_receipt).

        lv_receipt_index = lv_receipt_index + 1.

        DATA(lv_receipt_cid) =
          |COPY_RECEIPT_{ lv_claim_index }_{ lv_receipt_index }|.


        MODIFY ENTITIES OF zr_kf_ec_claim IN LOCAL MODE

          ENTITY zr_kf_ec_line

            CREATE BY \_RECEIPT

            FIELDS (
              receipt_file
              filename
              mimetype
              notes
            )

            WITH VALUE #(
              (
                %tky = ls_new_line_key-%tky

                %target = VALUE #(
                  (
                    %cid         = lv_receipt_cid
                    receipt_file = ls_source_receipt-receipt_file
                    filename     = ls_source_receipt-filename
                    mimetype     = ls_source_receipt-mimetype
                    notes        = ls_source_receipt-notes
                  )
                )
              )
            )

            MAPPED DATA(lt_mapped_receipt)
            FAILED DATA(lt_failed_receipt)
            REPORTED DATA(lt_reported_receipt).


        IF lt_failed_receipt-zr_kf_ec_receipt IS NOT INITIAL.

          lv_copy_failed = abap_true.
          EXIT.

        ENDIF.

      ENDLOOP.


      IF lv_copy_failed = abap_true.
        EXIT.
      ENDIF.

    ENDLOOP.


    " =========================================================
    " STEP 6: HANDLE ANY CHILD-COPY FAILURE
    " =========================================================

    IF lv_copy_failed = abap_true.

      APPEND VALUE #(
        %tky = ls_source_claim-%tky
      ) TO failed-zr_kf_ec_claim.

      APPEND VALUE #(
        %tky = ls_source_claim-%tky

        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = 'The Claim could not be copied with all Expense Lines and Receipts.'
        )

        %action-CopyClaim = if_abap_behv=>mk-on

      ) TO reported-zr_kf_ec_claim.

      CONTINUE.

    ENDIF.


    " =========================================================
    " STEP 7: READ AND RETURN THE NEW CLAIM
    " =========================================================

    READ ENTITIES OF zr_kf_ec_claim IN LOCAL MODE

      ENTITY zr_kf_ec_claim

        ALL FIELDS

        WITH VALUE #(
          ( %tky = ls_new_claim_key-%tky )
        )

        RESULT DATA(lt_new_claims).


    CHECK lt_new_claims IS NOT INITIAL.


    APPEND VALUE #(
      %tky   = ls_source_claim-%tky
      %param = lt_new_claims[ 1 ]
    ) TO result.

  ENDLOOP.

ENDMETHOD.

  METHOD massapprove.

  " Static action -> one parameter entry
  READ TABLE keys INTO DATA(ls_key) INDEX 1.

  CHECK sy-subrc = 0.

  DATA(lv_maximum_amount) =
    ls_key-%param-maximum_amount.


  " ==========================================
  " BR-15: Maximum Amount itself <= EUR 5,000
  " ==========================================

  IF lv_maximum_amount > 5000.

    APPEND VALUE #(
      %msg = new_message_with_text(
        severity = if_abap_behv_message=>severity-error
        text     = 'Mass approval refused: maximum amount cannot exceed EUR 5,000.00.'
      )
    ) TO reported-zr_kf_ec_claim.

    RETURN.

  ENDIF.


  " ==========================================
  " Find eligible Submitted Claims
  " ==========================================

  SELECT claim_uuid,
         status,
         total_amount
    FROM zr_kf_ec_claim
    WHERE status = 'Submitted'
      AND total_amount <= @lv_maximum_amount
    INTO TABLE @DATA(lt_claims_to_approve).


  " Nothing qualified
  IF lt_claims_to_approve IS INITIAL.

    APPEND VALUE #(
      %msg = new_message_with_text(
        severity = if_abap_behv_message=>severity-information
        text     = 'No claims qualified for mass approval.'
      )
    ) TO reported-zr_kf_ec_claim.

    RETURN.

  ENDIF.


  " ==========================================
  " Approve all qualifying Claims
  " ==========================================

  MODIFY ENTITIES OF zr_kf_ec_claim IN LOCAL MODE
    ENTITY zr_kf_ec_claim

      UPDATE FIELDS (
        status
        decision_date
      )

      WITH VALUE #(
        FOR ls_claim IN lt_claims_to_approve
        (
          claim_uuid    = ls_claim-claim_uuid
          status        = 'Approved'
          decision_date =
            cl_abap_context_info=>get_system_date( )
        )
      )

      FAILED DATA(lt_failed)
      REPORTED DATA(lt_reported).


  APPEND LINES OF lt_failed-zr_kf_ec_claim
    TO failed-zr_kf_ec_claim.

  APPEND LINES OF lt_reported-zr_kf_ec_claim
    TO reported-zr_kf_ec_claim.


  " ==========================================
  " Success message
  " ==========================================

  DATA(lv_approved_count) =
    lines( lt_claims_to_approve ).

  DATA(lv_message) =
    |{ lv_approved_count } claims were approved.|.


  APPEND VALUE #(
    %msg = new_message_with_text(
      severity = if_abap_behv_message=>severity-success
      text     = lv_message
    )
  ) TO reported-zr_kf_ec_claim.

ENDMETHOD.

  METHOD validateRequiredFields.

  READ ENTITIES OF zr_kf_ec_claim IN LOCAL MODE
    ENTITY zr_kf_ec_claim
    FIELDS (
      employee_name
      trip_purpose
      destination_country
      trip_start_date
      trip_end_date
      currency_code
    )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_claims).


  LOOP AT lt_claims INTO DATA(ls_claim).

    " Employee Name
    IF ls_claim-employee_name IS INITIAL.

      APPEND VALUE #(
        %tky = ls_claim-%tky
      ) TO failed-zr_kf_ec_claim.

      APPEND VALUE #(
        %tky = ls_claim-%tky

        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = 'Employee Name is required.'
        )

        %element-employee_name = if_abap_behv=>mk-on

      ) TO reported-zr_kf_ec_claim.

    ENDIF.


    " Trip Purpose
    IF ls_claim-trip_purpose IS INITIAL.

      APPEND VALUE #(
        %tky = ls_claim-%tky
      ) TO failed-zr_kf_ec_claim.

      APPEND VALUE #(
        %tky = ls_claim-%tky

        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = 'Trip Purpose is required.'
        )

        %element-trip_purpose = if_abap_behv=>mk-on

      ) TO reported-zr_kf_ec_claim.

    ENDIF.


    " Destination Country
    IF ls_claim-destination_country IS INITIAL.

      APPEND VALUE #(
        %tky = ls_claim-%tky
      ) TO failed-zr_kf_ec_claim.

      APPEND VALUE #(
        %tky = ls_claim-%tky

        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = 'Destination Country is required.'
        )

        %element-destination_country = if_abap_behv=>mk-on

      ) TO reported-zr_kf_ec_claim.

    ENDIF.


    " Trip Start Date
    IF ls_claim-trip_start_date IS INITIAL.

      APPEND VALUE #(
        %tky = ls_claim-%tky
      ) TO failed-zr_kf_ec_claim.

      APPEND VALUE #(
        %tky = ls_claim-%tky

        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = 'Trip Start Date is required.'
        )

        %element-trip_start_date = if_abap_behv=>mk-on

      ) TO reported-zr_kf_ec_claim.

    ENDIF.


    " Trip End Date
    IF ls_claim-trip_end_date IS INITIAL.

      APPEND VALUE #(
        %tky = ls_claim-%tky
      ) TO failed-zr_kf_ec_claim.

      APPEND VALUE #(
        %tky = ls_claim-%tky

        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = 'Trip End Date is required.'
        )

        %element-trip_end_date = if_abap_behv=>mk-on

      ) TO reported-zr_kf_ec_claim.

    ENDIF.


    " Currency
    IF ls_claim-currency_code IS INITIAL.

      APPEND VALUE #(
        %tky = ls_claim-%tky
      ) TO failed-zr_kf_ec_claim.

      APPEND VALUE #(
        %tky = ls_claim-%tky

        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = 'Currency is required.'
        )

        %element-currency_code = if_abap_behv=>mk-on

      ) TO reported-zr_kf_ec_claim.

    ENDIF.

  ENDLOOP.

ENDMETHOD.

ENDCLASS.
