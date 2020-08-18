//
// Created by gen on 6/23/2020.
//

#ifndef ANDROID_PROJECT_H
#define ANDROID_PROJECT_H

#include <core/Ref.h>
#include <nlohmann/json.hpp>
#include <core/Array.h>
#include "Settings.h"
#include "../gs_define.h"

namespace gs {
    class Context;
    class DataItem;
    class Settings;

    CLASS_BEGIN_N(Project, gc::Object)

        nlohmann::json config;
        bool validated = false;

        std::string path;
        std::string dir_name;

        std::string name;
        std::string subtitle;
        std::string url;
        std::string index;
        std::string book;
        std::string chapter;
        std::string search;
        gc::Variant search_data;

        gc::Array categories;

        std::shared_ptr<Settings> settings;
        std::string settings_path;

    public:

        METHOD void initialize(const std::string &path);

        METHOD bool isValidated() const {return validated;}

        METHOD const std::string &getName() const {return name;}
        METHOD const std::string &getSubtitle() const {return subtitle;}
        METHOD const std::string &getUrl() const {return url;}
        METHOD const std::string &getIndex() const {return index;}
        METHOD const std::string &getBook() const {return book;}
        METHOD const std::string &getChapter() const {return chapter;}
        METHOD const std::string &getSearch() const {return search;}
        METHOD const gc::Array &getCategories() const {return categories;}
        METHOD const std::string &getFullpath() const {return path;}
        METHOD const std::string &getPath() const {return dir_name;}
        METHOD const std::string &getSettingsPath() const {return settings_path;}

        METHOD static gc::Ref<Project> getMainProject();
        METHOD void setMainProject();

        METHOD gc::Ref<Context> createIndexContext(const gc::Variant &data);
        METHOD gc::Ref<Context> createBookContext(const gc::Ref<DataItem> &item);
        METHOD gc::Ref<Context> createChapterContext(const gc::Ref<DataItem> &item);
        METHOD gc::Ref<Context> createSearchContext();
        METHOD gc::Ref<Context> createSettingsContext();

        ON_LOADED_BEGIN(cls, gc::Object)
            INITIALIZER(cls, Project, initialize);
            ADD_METHOD(cls, Project, isValidated);
            ADD_METHOD(cls, Project, getName);
            ADD_METHOD(cls, Project, getSubtitle);
            ADD_METHOD(cls, Project, getUrl);
            ADD_METHOD(cls, Project, getIndex);
            ADD_METHOD(cls, Project, getBook);
            ADD_METHOD(cls, Project, getChapter);
            ADD_METHOD(cls, Project, getSearch);
            ADD_METHOD(cls, Project, getCategories);
            ADD_METHOD(cls, Project, getFullpath);
            ADD_METHOD(cls, Project, getPath);
            ADD_METHOD(cls, Project, getSettingsPath);
            ADD_METHOD(cls, Project, getMainProject);
            ADD_METHOD(cls, Project, setMainProject);

            ADD_METHOD(cls, Project, createIndexContext);
            ADD_METHOD(cls, Project, createBookContext);
            ADD_METHOD(cls, Project, createChapterContext);
            ADD_METHOD(cls, Project, createSearchContext);
            ADD_METHOD(cls, Project, createSettingsContext);
        ON_LOADED_END

    CLASS_END
}


#endif //ANDROID_PROJECT_H
