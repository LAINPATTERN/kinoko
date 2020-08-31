//
// Created by gen on 2020/5/27.
//

#ifndef ANDROID_COLLECTION_H
#define ANDROID_COLLECTION_H

#include <core/Ref.h>
#include <core/Map.h>
#include <core/Callback.h>
#include "../utils/Error.h"
#include "../gs_define.h"

namespace gs {
    class Settings;

    CLASS_BEGIN_N(Collection, gc::Object)

        bool loading = false;
        gc::Array data;
        gc::Variant info_data;
        std::shared_ptr<Settings> settings;
        std::string temp;
        std::string item_temp;

    public:

        ENUM_BEGIN(ChangeType)
            Reload = 1,
            Append = 2,
            Changed = 3
        ENUM_END

        Collection() {}

        METHOD void initialize(gc::Variant info_data);

        void setSettings(const std::shared_ptr<Settings> &settings) {
            this->settings = settings;
        }

        EVENT(bool, reload, gc::Map, gc::Callback);
        EVENT(bool, loadMore, gc::Callback);

        NOTIFICATION(dataChanged, ChangeType type, gc::Array array, int index);
        NOTIFICATION(loading, bool is_loading);
        NOTIFICATION(error, gc::Ref<Error>);
        NOTIFICATION(reloadComplete);

        bool reload(const gc::Map &data);
        bool loadMore();

        METHOD void setDataAt(const gc::Variant &var, int idx);
        METHOD void setData(const gc::Array &array);
        METHOD void appendData(const gc::Array &array);

        METHOD const gc::Array &getData() const {
            return data;
        }
        PROPERTY(data, getData, setData);

        METHOD const gc::Variant &getInfoData() const {
            return info_data;
        }
        METHOD void setInfoData(const gc::Variant &info_data) {
            this->info_data = info_data;
        }
        PROPERTY(info_data, getInfoData, setInfoData);

        METHOD const gc::Variant &getSetting(const std::string &key);
        METHOD void setSetting(const std::string &key, const gc::Variant &value);

        METHOD const std::string &getTemp() const {
            return temp;
        }
        METHOD void setTemp(const std::string &temp) {
            this->temp = temp;
        }
        PROPERTY(temp, getTemp, setTemp);

        METHOD const std::string &getItemTemp() const {
            return item_temp;
        }
        METHOD void setItemTemp(const std::string &temp) {
            item_temp = temp;
        }
        PROPERTY(item_temp, getItemTemp, setItemTemp);

        ON_LOADED_BEGIN(cls, gc::Object)
            INITIALIZER(cls, Collection, initialize);
            ADD_METHOD(cls, Collection, setDataAt);
            ADD_METHOD(cls, Collection, appendData);
            ADD_METHOD(cls, Collection, getSetting);
            ADD_PROPERTY(cls, "data", ADD_METHOD(cls, Collection, getData), ADD_METHOD(cls, Collection, setData));
            ADD_PROPERTY(cls, "info_data", ADD_METHOD(cls, Collection, getInfoData), ADD_METHOD(cls, Collection, setInfoData));
            ADD_PROPERTY(cls, "temp", ADD_METHOD(cls, Collection, getTemp), ADD_METHOD(cls, Collection, setTemp));
            ADD_PROPERTY(cls, "item_temp", ADD_METHOD(cls, Collection, getItemTemp), ADD_METHOD(cls, Collection, setItemTemp));
        ON_LOADED_END

    CLASS_END
}


#endif //ANDROID_COLLECTION_H
