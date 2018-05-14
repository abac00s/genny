(import os sys re argparse)

(setv *chunk-dir* ".")

(defn get-chunk [chunk-name &kwargs val]
  (setv base (os.path.join *chunk-dir* chunk-name))
  (for [ext [".html" ".htm"]]
    (setv file (+ base ext))
    (if (os.path.isfile file)
        (return (parse-html-file file #** val)))))


(defn parse-html [data &kwargs val]
  (setv data (re.sub r"\{\{\s*(\w+)\s*\}\}"
                     (fn [match]
                       (setv v (get match 1))
                       (if (in v val)
                           (get val v)
                           (do (print "No variable named " v)
                               None)))
                     data))
  (setv data (re.sub r"\{%\s*include\s*(\w+)\s*%\}"
                     (fn [match]
                       (get-chunk (get match 1) #** val))
                     data))
  (setv ext-match (re.search r"\{%\s*extends\s*(\w+)\s*%\}" data))
  (if ext-match (do (setv data (+ (cut data 0 (.start ext-match)) (cut data (.end ext-match))))
                    (setv data ((get-chunk (get ext-match 1) #** val) data))))
  (setv cont-match (re.search r"\{%\s*content\s*%\}" data))
  (if cont-match
      (do (setv pre (cut data 0 (.start cont-match)))
          (setv post (cut data (.end cont-match)))
          (fn [content] (+ pre content post)))
      data))


(defn parse-html-file [filename &kwargs val]
  (with [f (open filename "r")]
    (parse-html (.read f) #** val)))


(defmain [&rest _]
  (setv parser (argparse.ArgumentParser))
  (.add-argument parser "STRING"
                 :help "name of file to generate (without extension)")
  (.add-argument parser "-t" :type str :default "."
                 :help "directory with templates")
  (setv args (.parse-args parser))
  (setv *chunk-dir* args.t)
  (print (parse-html-file args.STRING)))
                     
