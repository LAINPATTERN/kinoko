//
// Created by gen on 2020/5/27.
//

#ifndef ANDROID_COLLECTION_H
#define ANDROID_COLLECTION_H

#include <core/Ref.h>
#include <core/Callback.h>
#include "../utils/Error.h"
#include "../gs_define.h"

namespace gs {

    ENUM_BEGIN(ChangeType)
        DataReload = 1,
        DataAppend = 2
    ENUM_END

    CLASS_BEGIN_N(Collection, gc::Object)

        bool loading = false;
        gc::Array data;
        gc::Variant info_data;

    public:

        Collection() {}

        METHOD void initialize(gc::Variant info_data);

        EVENT(bool, reload, gc::Callback);
        EVENT(bool, loadMore, gc::Callback);

        NOTIFICATION(dataChanged, gc::Array array, ChangeType type);
        NOTIFICATION(loading, bool is_loading);
        NOTIFICATION(error, gc::Ref<Error>);

        METHOD bool reload();
        METHOD bool loadMore();

        METHOD const gc::Array &getData() const {
            return data;
        }
        METHOD void setData(const gc::Array &data) {
            this->data.vec() = data->vec();
        }
        PROPERTY(data, getData, setData);

        METHOD const gc::Variant &getInfoData() const {
            return info_data;
        }
        METHOD void setInfoData(const gc::Variant &info_data) {
            this->info_data = info_data;
        }
        PROPERTY(info_data, getInfoData, setInfoData);

        ON_LOADED_BEGIN(cls, gc::Object)
            INITIALIZER(cls, Collection, initialize);
            ADD_METHOD(cls, Collection, reload);
            ADD_METHOD(cls, Collection, loadMore);
            ADD_PROPERTY(cls, "data", ADD_METHOD(cls, Collection, getData), ADD_METHOD(cls, Collection, setData));
            ADD_PROPERTY(cls, "info_data", ADD_METHOD(cls, Collection, getInfoData), ADD_METHOD(cls, Collection, setInfoData));
        ON_LOADED_END

    CLASS_END
}


#endif //ANDROID_COLLECTION_H
