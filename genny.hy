(import os sys re)

(setv *chunk-dir* ".")

(defn get-chunk [chunk-name &kwargs val]
  (setv base (os.path.join *chunk-dir* chunk-name))
  (for [ext [".html" ".htm"]]
    (setv file (+ base ext))
    (if (os.path.isfile file)
        (with [f (open file "r")]
          (return (parse-html (.read f) #** val))))))

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
                     
