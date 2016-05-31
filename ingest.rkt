#lang racket

;;;; provides utilities to snarf a Gregg Anniversary section into a directory tree of images

(provide
 (all-defined-out))

;;; ---------------------------------------------------------------------------------------------------
;;; IMPORTS & IMPLEMENTATION

(require net/url)
(require html-parsing)
(require sxml)

(define (url-for section)
  ;; String -> URL. Section should be something like "09". Values 01 through 36 are valid.
  (define url-string (string-append "http://gregg.angelfishy.net/anunit" section ".shtml"))
  (string->url url-string))

(define (page-for section-url)
  ;; url -> xexp. Snarfs the page and returns its xexp.
  (call/input-url section-url get-pure-port html->xexp))

(define (image-hierachy-from unit-table-xexp)
  ;; xexp -> hash<heading-string -> vector<image-url> >
  ;; TODO: grab out images and their headings
  ;; smoosh into nested structure
  ;; eventually, splorsh out onto disk with heading as folder title and downloaded images within the folders
  'wip)

(define (unit-table page-xexp)
  ;; xexp -> xexp. Digs out the table representing the unit content.
  (unit-table-query page-xexp))

(define unit-table-query
  ;; txpath query for the unit table
  (txpath "/descendant::table[3]"))

(define *unit-09*
  ;; convenience for repl'ing
  (page-for (url-for "09")))

(define any-unit-html
    "<?xml version=\"1.0\" encoding=\"iso-8859-1\"?>
<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">
<html xmlns=\"http://www.w3.org/1999/xhtml\"><!-- InstanceBegin template=\"/Templates/main.dwt\" codeOutsideHTMLIsLocked=\"false\" -->
<body>
<table width=\"948\" border=\"0\" cellpadding=\"0\" cellspacing=\"0\" class=\"text\">
  <tr> 
    <td width=\"182\" valign=\"top\" bgcolor=\"#CCCCCC\" class=\"unnamed1\">
      <table width=\"186\" border=\"0\" cellpadding=\"2\" cellspacing=\"2\" class=\"text\">
      </table>
    </td>
    <!-- InstanceBeginEditable name=\"EditRegion3\" -->
    <td width=\"585\" valign=\"top\" bgcolor=\"#FFFFFF\"><table width=\"100%\" border=\"0\" cellpadding=\"2\" cellspacing=\"2\">
        <tr> 
          <td width=\"79%\" colspan=\"2\" class=\"text\"><p align=\"center\"><strong>Unit 
              9</strong></p>
            <p align=\"center\"><strong>The Th Joinings</strong></p>
            <p align=\"left\">&nbsp; &nbsp; &nbsp;<strong><a name=\"p78\" id=\"p78\"></a>78.</strong> 
              &nbsp;The left-motion <em>th</em> is used before and after <em>o</em>, 
              <em>r</em>, <em>l</em>. &nbsp;In other cases the right-motion <em>th</em> 
              is used:</p>
            <p align=\"center\"><img src=\"images/gregg092.gif\" alt=\"though, although, thought, throw, throat, thrown, author, earth, health, both, birth, path, bath, teeth, thief, theater, thin, cloth\" width=\"376\" height=\"216\" /></p>
            <p align=\"left\">&nbsp; &nbsp; &nbsp;*The word <em>although</em> is 
              a combination of <em>all</em> and <em>though</em>.&nbsp;</p>
            <p align=\"left\">&nbsp; &nbsp; &nbsp;<a name=\"p79\" id=\"p79\"></a><strong>79.</strong> 
              &nbsp;When <em>th</em> is the only consonant stroke, as in the brief 
              forms for <em>that</em> or <em>they</em>, or is in combination with 
              <em>s</em>, the right-motion <em>th</em> is used, as in <em>these</em> 
              and <em>seethe</em>.</p>
            <p align=\"center\"><strong>Frequent Prefixes and Suffixes</strong></p>
            <p align=\"left\">&nbsp; &nbsp; &nbsp;<strong><a name=\"p80\" id=\"p80\"></a>80.</strong> 
              &nbsp;The prefixes <em>con</em>, <em>com</em>, <em>coun</em>, <em>cog</em>, 
              followed by a consonant, are expressed by <em>k</em>. &nbsp;The 
              suffix <em>ly</em> is expressed by a small circle, <em>ily</em> 
              and <em>ally</em>, by a loop.</p>
            <p align=\"center\"><img src=\"images/gregg093.gif\" alt=\"confess,  confer, convention, convey, convince, concrete, safely, solely, only, council, compel lonely, lately, early, fairly, wholly, hardly, heartily, conform, county, formally, easily, hastily, readily, family, totally, socially\" width=\"378\" height=\"291\" /></p>
            <p align=\"left\">&nbsp; &nbsp; &nbsp;<a name=\"p81\" id=\"p81\"></a><strong>81.</strong> 
              &nbsp;In words beginning with <em>comm</em> or <em>conn</em>, the 
              second <em>m</em> or <em>n</em> is written, thus:</p>
            <p align=\"center\"><img src=\"images/gregg094.gif\" alt=\"common, connote, commence\" width=\"400\" height=\"29\" /></p>
            <p align=\"left\">&nbsp; &nbsp; &nbsp;When <em>con</em> or <em>com</em> 
              is followed by a vowel or by <em>r</em> or <em>l</em>, write <em>kn</em> 
              for <em>con</em> and <em>km</em> for <em>com</em>, thus:</p>
            <p align=\"center\"><img src=\"images/gregg095.gif\" alt=\"comedy, comrade, comic\" width=\"400\" height=\"36\" /></p>
            <p align=\"center\"><strong><a name=\"p87\" id=\"p87\"></a>87.&nbsp; Frequent 
              Phrases</strong></p>
            <p align=\"center\"><img src=\"images/gregg101.gif\" alt=\"Frequent Phrases\" width=\"382\" height=\"414\" /></p>
            <p align=\"center\"><strong><a name=\"p88\" id=\"p88\"></a>88. &nbsp;Brief 
              Forms for Common Words</strong></p>
            <p align=\"center\"><img src=\"images/gregg102.gif\" alt=\"Brief forms\" width=\"400\" height=\"205\" /></p>
            <p align=\"left\">&nbsp; &nbsp; &nbsp;*The prefix form for <em>agr-e-i</em>, 
              a loop written above the following character, is used to express 
              the word <em>agree</em>.<br />
              &nbsp; &nbsp; &nbsp;&#8224;The angle between <em>k</em> and <em>p</em> 
              is maintained in the word complete to make a distinction between 
              <em>complete</em> and <em>keep</em>. </p>
            <p align=\"center\"><strong><a name=\"p89\" id=\"p89\"></a>89.&nbsp; &nbsp;Reading 
              and Dictation Practice</strong></p>
            <p align=\"center\"><img src=\"images/gregg103.gif\" alt=\"Reading and Dictation Practice\" width=\"387\" height=\"527\" /></p>
            <p align=\"center\"><strong><a name=\"p90\" id=\"p90\"></a>90. &nbsp;Writing 
              Practice</strong></p>
            <p>&nbsp; &nbsp; &nbsp;1. &nbsp;It is hard to say what is known about 
              the model of the motor on which Horace Holiday is working. &nbsp;Several 
              people have seen it and praise it.<br />
              &nbsp; &nbsp; &nbsp;2. &nbsp;After Bob bought the boat he noticed 
              that the motor would stall often. &nbsp;After much analysis and 
              pottering over it, he spotted the cause of grief. &nbsp;It was a 
              little thing, and easy to fix.<br />
              &nbsp; &nbsp; &nbsp;3. &nbsp;The history of this country shows that 
              a hardy, hard-working people, gifted with vision, can achieve what 
              they fix as a goal if the goal has meaning to the people in general.<br />
              &nbsp; &nbsp; &nbsp;4. &nbsp;It was a shock to her to hear that 
              John Jones, after joking about it, really had started alone on an 
              airplane trip to Havana and was nearing his goal.<br />
              &nbsp; &nbsp; &nbsp;5. &nbsp;The &quot;Lone Eagle&quot; did not 
              cross the ocean merely by dreaming of it. &nbsp;He made ready for 
              a great trip by planning every detail. &nbsp;Study, hard work, and 
              the bravery to face peril without flinching helped him to achieve 
              his aim and to place his name on the scroll of the great men of 
              history.</p>
            <p style=\"text-align: justify\">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Dear Sir: &nbsp;It will be necessary 
              for me to stay here till about the end of January, as there are 
              many matters of importance still to be finished. &nbsp;I am really 
              glad that you were able to see Mr. Hartman and close that business 
              with him. &nbsp;Such matters may easily cause hard feeling. &nbsp;There 
              is nothing at present that needs your presence here. The general 
              situation seems to be as good as it is in the East. &nbsp;I have 
              my heart set on making big gains for the company here this month. 
              &nbsp;I am working hard to achieve all possible. &nbsp;Yours truly,</p><p align=\"center\"><a href=\"trpanu09.shtml\"><em>Transcription Key to 
              this Unit</em></a><strong><br />
        </tr>
      </table></td>
    <!-- InstanceEndEditable -->
          </table>
        </div>
      </div></td>
  </tr>
</table>
</body>
<!-- InstanceEnd --></html>")

(define any-unit-xexp
  (html->xexp any-unit-html))

(module+ test
  (require rackunit)
  (check-equal? (url->string (url-for "09")) "http://gregg.angelfishy.net/anunit09.shtml" "happy path")
  )
