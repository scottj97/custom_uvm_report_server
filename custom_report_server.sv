// Time-stamp: <2017-07-28 16:01:51 kmodi>

//------------------------------------------------------------------------------
// File Name    : custom_report_server.sv
// Author       : Kaushal.Modi@analog.com
// Description  : Custom format the uvm_info messages
//                * Use the following at command line to customize the report
//                  server
//                  - +UVM_REPORT_NOCOLOR - Do not color format the messages.
//                  - +UVM_REPORT_NOMSGWRAP - Do not wrap long messages.
//                  - +UVM_REPORT_TRACEBACK=NONE - Do not print the traceback info
//                                     such class name, file name, line number.
//                  - +UVM_REPORT_TRACEBACK=ALL - Always print the traceback info.
//                    Note: Traceback info will not be shown by default for
//                          UVM_LOW and UVM_MEDIUM verbosity level if neither of
//                          above two traceback info command line args are used.
//                * Auto wrap the messages and traceback infos.
//                * If the last character of the ID field of an uvm_info is '*',
//                  that message display will emulate a $display,
//                   - Severity tag, time stamp, id and traceback info will not
//                     be printed.
//                   - Message will not be auto-wrapped.
//                   - '*' will be removed from the ID string and the msg id
//                     counter for this modified string will be incremented.
//                     If the user entered ID as "RXQEC_TABLE*", the id counter
//                     for "RXQEC_TABLE" will be incremented.
//                * If the background color of the terminal is white or a light
//                  color, set the environment variable TERM_BG_LIGHT to 1 before
//                  running the sims. If that value is 0 or if that variable is
//                  not set, a dark background terminal will be assumed.
//------------------------------------------------------------------------------

import "DPI-C" function string getenv(input string env_var);

class custom_report_server extends uvm_default_report_server;


   // identation size = 11(%11s) + 1 space + 1("@") + 7(%7t) + 2("ns") +
   //                   2 spaces (%2s) + 2(extra indentation) = 26
   parameter INDENT                          = 26;
   parameter MAX_MSG_CHARS_PER_LINE          = 75 - INDENT;
   // Do not wrap the message is it takes more than 20 lines to do so
   parameter MAX_MSG_LEN_FOR_WRAP            = 20*MAX_MSG_CHARS_PER_LINE;
   parameter NUM_CONSEC_DASH_TO_DETECT_TABLE = 15;

   string indentation_str           = {INDENT{" "}};

   typedef enum {BLACK    , GRAY,GREY , UBLACK,
                 RED      , BRED      , URED,
                 GREEN    , BGREEN    , UGREEN,
                 YELLOW   , BYELLOW   , UYELLOW,
                 BLUE     , BBLUE     , UBLUE,
                 MAGENTA  , BMAGENTA  , UMAGENTA,
                 CYAN     , BCYAN     , UCYAN,
                 WHITE    , BWHITE    , UWHITE,
                 NOCHANGE , BOLD      , ULINE} color_t;

   string fg_format[color_t] = '{BLACK    : "0;30",
                                 GRAY     : "0;90",
                                 GREY     : "0;90",
                                 UBLACK   : "4;30",
                                 RED      : "0;31",
                                 BRED     : "0;91",
                                 URED     : "4;31",
                                 GREEN    : "0;32",
                                 BGREEN   : "0;92",
                                 UGREEN   : "4;32",
                                 YELLOW   : "0;33",
                                 BYELLOW  : "0;93",
                                 UYELLOW  : "4;33",
                                 BLUE     : "0;34",
                                 BBLUE    : "0;94",
                                 UBLUE    : "4;34",
                                 MAGENTA  : "0;35",
                                 BMAGENTA : "0;95",
                                 UMAGENTA : "4;35",
                                 CYAN     : "0;36",
                                 BCYAN    : "0;96",
                                 UCYAN    : "4;36",
                                 WHITE    : "0;37",
                                 BWHITE   : "0;97",
                                 UWHITE   : "4;37",
                                 NOCHANGE : "0",
                                 BOLD     : "1",
                                 ULINE    : "4"};

   string bg_format[color_t] = '{BLACK    : ";40",
                                 RED      : ";41",
                                 GREEN    : ";42",
                                 YELLOW   : ";43",
                                 BLUE     : ";44",
                                 MAGENTA  : ";45",
                                 CYAN     : ";46",
                                 WHITE    : ";47",
                                 NOCHANGE : ""};

   color_t c_uvm_info[2];
   color_t c_uvm_warning[2];
   color_t c_uvm_error[2];
   color_t c_uvm_fatal[2];
   color_t c_time[2];
   color_t c_message[2];
   color_t c_id[2];
   color_t c_tracebackinfo[2];

   bit uvm_report_nocolor;
   bit uvm_report_nomsgwrap;

   typedef enum bit [1:0] { UVM_REPORT_TRACEBACK_NONE,
                            UVM_REPORT_TRACEBACK_HIGHPLUS,
                            UVM_REPORT_TRACEBACK_ALL } uvm_report_traceback_e;
   uvm_report_traceback_e uvm_report_traceback;

   string severity_strings[uvm_severity]; // colorized "UVM_INFO", "UVM_WARNING", etc

   function new(string name = "custom_report_server");
      super.new(name);

      uvm_report_nocolor = $test$plusargs("UVM_REPORT_NOCOLOR");
      uvm_report_nomsgwrap = $test$plusargs("UVM_REPORT_NOMSGWRAP");

      if ($test$plusargs("UVM_REPORT_TRACEBACK=NONE")) begin
         uvm_report_traceback = UVM_REPORT_TRACEBACK_NONE;
      end else if ($test$plusargs("UVM_REPORT_TRACEBACK=ALL")) begin
         uvm_report_traceback = UVM_REPORT_TRACEBACK_ALL;
      end else begin
         uvm_report_traceback = UVM_REPORT_TRACEBACK_HIGHPLUS;
      end

      if ( getenv("TERM_BG_LIGHT") == "1" ) begin
         c_uvm_info       = {GREY     ,NOCHANGE};
         c_uvm_warning    = {BLACK    ,YELLOW};
         c_uvm_error      = {WHITE    ,RED};
         c_uvm_fatal      = {BLACK    ,RED};
         c_time           = {BLUE     ,NOCHANGE};
         c_message        = {NOCHANGE ,NOCHANGE};
         c_id             = {BLUE     ,NOCHANGE};
         c_tracebackinfo  = {GREY     ,NOCHANGE};
      end else begin
         c_uvm_info       = {GREY     ,NOCHANGE};
         c_uvm_warning    = {BLACK    ,YELLOW};
         c_uvm_error      = {WHITE    ,RED};
         c_uvm_fatal      = {BLACK    ,RED};
         c_time           = {CYAN     ,NOCHANGE};
         c_message        = {NOCHANGE ,NOCHANGE};
         c_id             = {CYAN     ,NOCHANGE};
         c_tracebackinfo  = {GREY     ,NOCHANGE};
      end

      severity_strings[UVM_INFO   ] = {"   ", colorize("UVM_INFO", c_uvm_info)};
      severity_strings[UVM_WARNING] = colorize("UVM_WARNING", c_uvm_warning);
      severity_strings[UVM_ERROR  ] = {"  ", colorize("UVM_ERROR", c_uvm_error)};
      severity_strings[UVM_FATAL  ] = {"  ", colorize("UVM_FATAL", c_uvm_fatal)};

      enable_report_id_count_summary = 0; // no need for that verbose junk
   endfunction // new

   local function string colorize(string str, const ref color_t colors[2]);
      if (uvm_report_nocolor) return str;
      return {"\033[", fg_format[colors[0]], bg_format[colors[1]], "m", str, "\033[0m"};
   endfunction: colorize

   local function string basename(const ref string filename);
      int i = filename.len()-1;
      while (i >= 0 && filename[i] != "/") i--;  // find last slash, if any
      if (i < 0) return filename;  // no slash found
      return filename.substr(i+1, filename.len()-1);
   endfunction: basename

   local function string wordwrap(string message, const ref string report_object_name, bit emulate_dollardisplay);
      string message_str       = "";
      bit add_newline          = 0;
      int dash_cnt             = 0;

      if ( uvm_report_nomsgwrap ) return message;

      // If the last character of message is a newline, replace it with
      // space
      if ( message[message.len()-1]=="\n" ) begin
         message[message.len()-1] = " ";
      end

      // Wrap the message string if it's too long.
      // Do not wrap the lines so that they break words (makes searching difficult)
      // Do NOT wrap the message IF,
      //  - message len > MAX_MSG_LEN_FOR_WRAP
      //  - emulate_dollardisplay == 1
      if ( report_object_name=="reporter" ||
           message.len()>MAX_MSG_LEN_FOR_WRAP ||
           emulate_dollardisplay==1 )
         return message;
      foreach(message[i]) begin
         if ( message[i]=="-" ) begin
            dash_cnt++;
         end else begin
            dash_cnt = 0;
         end
         // If more than NUM_CONSEC_DASH_TO_DETECT_TABLE consecutive
         // dashes are detected, do not wrap the message as it could
         // be a pre-formatted string output by the uvm_printer.
         if ( dash_cnt > NUM_CONSEC_DASH_TO_DETECT_TABLE ) begin
            return message;
         end

         // Set the "add_newline" flag so that newline is added as soon
         // as a 'wrap-friendly' character is detected
         if ( (i+1)%MAX_MSG_CHARS_PER_LINE==0) begin
            add_newline = 1;
         end

         if (add_newline &&
             // add newline only if the curr char is 'wrap-friendly'
             ( message[i]==" " || message[i]=="." || message[i]==":" ||
               message[i]=="/" || message[i]=="=" ||
               i==(message.len()-1) )) begin
            message_str = {message_str, message[i],"\n", indentation_str};
            add_newline = 0;
         end else begin
            message_str = {message_str, message[i]};
         end
      end // foreach (message[i])
      return message_str;
   endfunction: wordwrap

   virtual function string compose_report_message(uvm_report_message report_message,
                                                  string report_object_name = "");
      uvm_severity l_severity;
      uvm_report_message_element_container el_container;
      string message  = "";
      string id       = "";

      // Declare function-internal vars
      bit    emulate_dollardisplay     = 0;
      string message_str               = "";
      string severity_str              = "";
      string time_str                  = "";
      string id_str                    = "";
      string my_composed_message       = "";

      if (report_object_name == "") begin
         uvm_report_handler l_report_handler;
         l_report_handler = report_message.get_report_handler();
         report_object_name = l_report_handler.get_full_name();
      end

      // --------------------------------------------------------------------
      // SEVERITY
      l_severity = report_message.get_severity();

      id = report_message.get_id();

      if (l_severity==UVM_INFO) begin
         // Emulate $display if the last char of the uvm_info ID field is '*'
         if (id[id.len()-1]=="*") begin
            emulate_dollardisplay = 1;
            // Remove that last '*' character from the ID string
            id = id.substr(0, id.len()-2);
         end // if (id[id.len()-1]=="*")
      end
      severity_str = severity_strings[l_severity];
      // end SEVERITY

      // --------------------------------------------------------------------
      // TIME
      // Note: Add the below statement in the initial block in top.sv along
      // with run_test()
      /*
       // Print the simulation time in ns by default
       $timeformat(-9, 0, "", 11);  // units, precision, suffix, min field width
       */
      time_str = {"@", colorize($sformatf("%7t", $time), c_time), "ns"};
      // end TIME

      // --------------------------------------------------------------------
      // MESSAGE + ID

      el_container = report_message.get_element_container();
      if (el_container.size() == 0)
         message = report_message.get_message();
      else begin
         string prefix = uvm_default_printer.knobs.prefix;
         uvm_default_printer.knobs.prefix = " +";
         message = {report_message.get_message(), "\n", el_container.sprint()};
         uvm_default_printer.knobs.prefix = prefix;
      end

      message_str = wordwrap(message, report_object_name, emulate_dollardisplay);

      if (emulate_dollardisplay) begin
         my_composed_message = message_str;
      end else begin
         bit add_traceback = 0;

         // Append the id string to message_str
         message_str  = colorize(message_str, c_message);
         id_str       = colorize(id, c_id);
         message_str  = {message_str, " :", id_str};
         // end MESSAGE + ID

         // --------------------------------------------------------------------
         // FINAL PRINTED MESSAGE
         my_composed_message = $sformatf("%5s %s  %s",
                                         severity_str, time_str,
                                         message_str);
         if ( uvm_report_traceback == UVM_REPORT_TRACEBACK_ALL ) begin
            add_traceback = 1;
         end else if ( uvm_report_traceback != UVM_REPORT_TRACEBACK_NONE ) begin
            uvm_verbosity l_verbosity;
            string verbosity_str;
            // By default do not print the traceback info only for
            // UVM_LOW and UVM_MEDIUM verbosity messages
            if ($cast(l_verbosity, report_message.get_verbosity()))
               verbosity_str = l_verbosity.name();
            else
               verbosity_str.itoa(report_message.get_verbosity());

            if ( verbosity_str!="UVM_LOW"
                 && verbosity_str!="UVM_MEDIUM")
               add_traceback = 1;
         end

         if (add_traceback) begin
            string filename;
            string filename_str;
            string tracebackinfo_str;
            int line;
            // --------------------------------------------------------------------
            // REPORT_OBJECT_NAME + FILENAME + LINE NUMBER
            // Extract just the file name, remove the preceeding path
            filename = report_message.get_filename();
            line     = report_message.get_line();
            if (filename=="")
               filename_str = "";
            else
               filename_str = $sformatf("%s(%0d)", basename(filename), line);

            // The traceback info will be indented with respect to the message_str
            if ( report_object_name=="reporter" )
               tracebackinfo_str = {" ", report_object_name, "\n"};
            else begin
               tracebackinfo_str = {report_object_name, ", ", filename_str};
               if ( tracebackinfo_str.len() > MAX_MSG_CHARS_PER_LINE ) begin
                  tracebackinfo_str = {"\n", indentation_str, report_object_name, ",",
                                       "\n", indentation_str, filename_str};
               end else begin
                  tracebackinfo_str = {"\n", indentation_str, tracebackinfo_str};
               end
            end
            tracebackinfo_str = colorize(tracebackinfo_str, c_tracebackinfo);
            // end REPORT_OBJECT_NAME + FILENAME + LINE NUMBER
            my_composed_message = {my_composed_message, tracebackinfo_str};
         end // if (add_traceback)
      end // else: !if(emulate_dollardisplay)
      // end FINAL PRINTED MESSAGE

      compose_report_message = my_composed_message;
   endfunction // compose_report_message

endclass // custom_report_server
